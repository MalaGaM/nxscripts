################################################################################
# nxTools - Sitebot Commands                                                   #
################################################################################
# Author  : $-66(AUTHOR) #
# Date    : $-66(TIMESTAMP) #
# Version : $-66(VERSION) #
################################################################################

# Load Libraries
######################################################################

if {[catch {source [file join [file dirname [info script]] "nxLib.itcl"]} ErrorMsg]} {
    iputs "Error loading nxLib: $ErrorMsg"; return
}

# Bot Procedures
######################################################################

proc BotAuth {UserName Password} {
    set Valid 0
    if {[userfile open $UserName] == 0} {
        set UserFile [userfile bin2ascii]
        foreach UserLine [split $UserFile "\r\n"] {
            if {[string equal -nocase "password" [lindex $UserLine 0]]} {
                set UserHash [lindex $UserLine 1]; break
            }
        }
        if {[string equal -nocase $UserHash [sha1 $Password]]} {set Valid 1}
    }
    if {$Valid} {iputs "AUTH|Success"} else {iputs "AUTH|Failed"}
    return 0
}

proc BotUserStats {StatsType Target StartIndex EndIndex} {
    set StatsList ""
    foreach UserName [GetUserList] {
        set Found 0; set GroupName "NoGroup"
        set FileStats 0; set SizeStats 0; set TimeStats 0
        if {[userfile open $UserName] != 0} {continue}
        set UserFile [userfile bin2ascii]
        foreach UserLine [split $UserFile "\r\n"] {
            set LineType [string tolower [lindex $UserLine 0]]
            if {[string equal "groups" $LineType]} {
                set GroupName [GetGroupName [lindex $UserLine 1]]
                incr Found
            } elseif {[string equal $StatsType $LineType]} {
                MergeStats [lrange $UserLine $StartIndex $EndIndex] FileStats SizeStats TimeStats
                incr Found
            }
            if {$Found == 2} {break}
        }
        lappend StatsList [list $UserName $GroupName $FileStats $SizeStats $TimeStats]
    }

    ## Sort user stats
    set Count 0
    set StatsList [lsort -decreasing -integer -index 3 $StatsList]
    foreach UserStats $StatsList {
        incr Count
        foreach {UserName GroupName FileStats SizeStats TimeStats} $UserStats {break}
        if {![string match $Target $UserName]} {continue}
        iputs "USTATS|[format %02d $Count]|$UserName|$GroupName|$FileStats|$SizeStats|$TimeStats"
    }
    return 0
}

proc BotGroupStats {StatsType Target StartIndex EndIndex} {
    set StatsList ""
    foreach GroupName [GetGroupList] {
        set FileStats 0; set SizeStats 0; set TimeStats 0
        foreach UserName [GetGroupUsers [resolve group $GroupName]] {
            if {[userfile open $UserName] != 0} {continue}
            set UserFile [userfile bin2ascii]
            foreach UserLine [split $UserFile "\r\n"] {
                if {[string equal -nocase $StatsType [lindex $UserLine 0]]} {
                    MergeStats [lrange $UserLine $StartIndex $EndIndex] FileStats SizeStats TimeStats
                    break
                }
            }
        }
        lappend StatsList [list $GroupName $FileStats $SizeStats $TimeStats]
    }

    ## Sort group stats
    set Count 0
    set StatsList [lsort -decreasing -integer -index 2 $StatsList]
    foreach GroupStats $StatsList {
        incr Count
        foreach {GroupName FileStats SizeStats TimeStats} $GroupStats {break}
        if {![string match $Target $GroupName]} {continue}
        iputs "GSTATS|[format %02d $Count]|$GroupName|$FileStats|$SizeStats|$TimeStats"
    }
    return 0
}

proc BotUserInfo {UserName Section} {
    if {![string is digit -strict $Section] || $Section > 9} {set Section 1} else {incr Section}
    array set user [list Credits 0 Flags "" Group "NoGroup" Ratio 0 TagLine "No Tagline Set"]
    set file(alldn) 0; set size(alldn) 0; set time(alldn) 0
    set file(allup) 0; set size(allup) 0; set time(allup) 0

    if {[userfile open $UserName] != 0} {return 1}
    set UserFile [userfile bin2ascii]
    foreach UserLine [split $UserFile "\r\n"] {
        set LineType [string tolower [lindex $UserLine 0]]
        switch -exact -- $LineType {
            {alldn} - {allup} {MergeStats [lrange $UserLine 1 end] file($LineType) size($LineType) time($LineType)}
            {credits} {set user(Credits) [lindex $UserLine $Section]}
            {flags}   {set user(Flags) [lindex $UserLine 1]}
            {groups}  {set user(Group) [GetGroupName [lindex $UserLine 1]]}
            {ratio}   {set user(Ratio) [lindex $UserLine $Section]}
            {tagline} {set user(TagLine) [string map {| ""} [ArgRange $UserLine 1 end]]}
        }
    }
    iputs "USER|$UserName|$user(Group)|$user(Flags)|$user(TagLine)|$user(Credits)|$user(Ratio)|$file(alldn)|$size(alldn)|$time(alldn)|$file(allup)|$size(allup)|$time(allup)"
    return 0
}

proc BotWho {} {
    if {[client who init "CID" "UID" "IDENT" "IP" "STATUS" "ACTION" "TIMEIDLE" "TRANSFERSPEED" "VIRTUALPATH" "VIRTUALDATAPATH"] == 0} {
        while {[set WhoData [client who fetch]] != ""} {
            foreach {ClientId UserId Ident IP Status Action IdleTime Speed VirtualPath DataPath} $WhoData {break}
            set UserName [resolve uid $UserId]
            set GroupName "NoGroup"
            if {[string equal -nocase "pass" [lindex $Action 0]]} {set Action "[lindex $Action 0] *****"}
            set FileName [file tail $DataPath]
            set Speed [expr {double($Speed)}]

            ## Find the user's group name
            if {[userfile open $UserName] == 0} {
                set UserFile [userfile bin2ascii]
                foreach UserLine [split $UserFile "\r\n"] {
                    if {[string equal -nocase "groups" [lindex $UserLine 0]]} {
                        set GroupName [GetGroupName [lindex $UserLine 1]]; break
                    }
                }
            }
            switch -exact -- $Status {
                0 - 3 {set Status "IDLE"}
                1 {set Status "DNLD"}
                2 {set Status "UPLD"}
                default {continue}
            }
            iputs "WHO|$ClientId|$UserName|$GroupName|$Ident|$IP|$Status|$Action|$VirtualPath|$FileName|$IdleTime|$Speed"
        }
    }
    return 0
}

proc BotMain {ArgV} {
    global misc ioerror
    if {[IsTrue $misc(DebugMode)]} {DebugLog -state [info script]}

    ## Safe argument handling
    set ArgLength [llength [set ArgList [ArgList $ArgV]]]
    set Action [string tolower [lindex $ArgList 0]]
    set Result 0
    switch -exact -- $Action {
        {auth} {
            if {$ArgLength > 2} {
                set Result [BotUserInfo [lindex $ArgList 1] [lindex $ArgList 2]]
            } else {
                iputs "Syntax: SITE BOT AUTH <username> <password>"
            }
        }
        {bw} {
        }
        {stats} {
            if {$ArgLength > 2} {
                foreach {Action Param1 Param2 Param3} $args {break}

                ## Check stats type
                set StatsType [string tolower [lindex $ArgList 1]]
                if {[lsearch -exact {alldn allup daydn dayup monthdn monthup wkdn wkup} $StatsType] == -1} {
                    set StatsType "Stats"
                }

                ## Check section number
                set Section [lindex $ArgList 2]
                if {![string is digit -strict $Section] || $Section > 9} {
                    set StartIndex 1
                    set EndIndex "end"
                } else {
                    set StartIndex [incr Section]
                    set EndIndex [incr Section 2]
                }

                ## User or group stats
                if {[string index [set Target [lindex $ArgList 2]] 0] == "="} {
                    set Target [string range $Target 1 end]
                    set Result [BotGroupStats $StatsType $Target $StartIndex $EndIndex]
                } else {
                    set Result [BotUserStats $StatsType $Target $StartIndex $EndIndex]
                }
            } else {
                iputs "Syntax: STATS <stats type> <username/=group> \[stats section\]"
            }
        }
        {user} {
            if {$ArgLength > 2} {
                set Result [BotUserInfo [lindex $ArgList 1] [lindex $ArgList 2]]
            } else {
                iputs "Syntax: SITE BOT USER <username> \[credit section\]"
            }
        }
        {who} {
            set Result [BotWho]
        }
        default {
            iputs "Syntax: SITE BOT <arguments>"
        }
    }
    return [set ioerror $Result]
}

BotMain [expr {[info exists args] ? $args : ""}]