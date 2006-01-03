#
# AlcoBot - Alcoholicz site bot.
# Copyright (c) 2005 Alcoholicz Scripting Team
#
# Module Name:
#   glFTPD Data Module
#
# Author:
#   neoxed (neoxed@gmail.com) Nov 13, 2005
#
# Abstract:
#   Implements a module to interact with glFTPD's binary data files.
#

namespace eval ::alcoholicz::GlData {
    variable logsPath
    if {![info exists logsPath]} {
        set logsPath ""
    }
    namespace import -force ::alcoholicz::*
    namespace import -force ::alcoholicz::FtpDaemon::*
}

####
# OpenBinaryFile
#
# Opens a binary file located in glFTPD's log directory.
#
proc ::alcoholicz::GlData::OpenBinaryFile {name {mode "r"}} {
    variable logsPath
    set filePath [file join $logsPath $name]
    if {[catch {set handle [open $filePath $mode]} message]} {
        LogError ModGlData $message
        return ""
    }
    fconfigure $handle -translation binary
    return $handle
}

####
# StructOpen
#
# Opens glFTPD binary structure file for reading.
#
proc ::alcoholicz::GlData::StructOpen {name handleVar {backwards 1}} {
    variable structHandles
    variable structLength
    upvar $handleVar handle

    # Sanity check.
    if {![info exists structLength($name)]} {
        error "invalid structure name \"$name\""
    }
    set handle [OpenBinaryFile $name]
    if {$handle eq ""} {return 0}

    # Set the file access pointer to the end if we are reading
    # the file backwards (newer entries are at the end).
    if {[set backwards [IsTrue $backwards]]} {
        seek $handle 0 end
    }

    # Format: backwards structName structLength
    set structHandles($handle) [list $backwards $name $structLength($name)]
    return 1
}

####
# StructRead
#
# Reads an entry from a glFTPD binary file.
#
proc ::alcoholicz::GlData::StructRead {handle dataVar} {
    variable structHandles
    upvar $dataVar data
    foreach {backwards structName structLength} $structHandles($handle) {break}

    if {$backwards && [catch {seek $handle -$structLength current}]} {
        # We've reached the beginning of the file.
        return 0
    }
    set data [read $handle $structLength]
    if {[string length $data] != $structLength} {
        return 0
    }
    if {$backwards} {
        seek $handle -$structLength current
    }
    return 1
}

####
# StructClose
#
# Closes a glFTPD binary file.
#
proc ::alcoholicz::GlData::StructClose {handle} {
    variable structHandles
    unset structHandles($handle)
    close $handle
}

####
# Dupe
#
# Search the dupelog for a release, command: !dupe [-limit <num>] <pattern>.
#
proc ::alcoholicz::GlData::Dupe {command target user host handle channel argv} {
    variable logsPath

    # Parse command options.
    set option(limit) -1
    if {[catch {set pattern [GetOptions $argv {{limit integer}} option]} message]} {
        CmdSendHelp $channel channel $command $message
        return
    }
    if {[set pattern [join $pattern]] eq ""} {
        CmdSendHelp $channel channel $command "you must specify a pattern"
        return
    }
    set limit [GetResultLimit $option(limit)]
    SendTargetTheme $target dupeHead [list $pattern]

    set data [list]
    if {![catch {set handle [open [file join $logsPath "dupelog"] r]} message]} {
        set range [expr {$limit - 1}]

        while {![eof $handle]} {
            # Every line in the dupelog file should be at least eight
            # characters (timestamp is 6 characters, a space, and a path).
            if {[gets $handle line] < 8} {continue}
            set release [string range $line 7 end]

            if {[string match -nocase $pattern $release]} {
                set data [lrange [linsert $data 0 $line] 0 $range]
            }
        }
        close $handle
    } else {
        LogError ModGlData $message
    }

    # Display results.
    if {[llength $data]} {
        set count 0
        foreach item $data {
            incr count
            set month [string range $item 0 1]
            set day   [string range $item 2 3]
            set year  [string range $item 4 5]
            set time  [clock scan "$month/$day/$year"]
            set release [string range $item 7 end]

            SendTargetTheme $target dupeBody [list $count $release $time]
        }
    } else {
        SendTargetTheme $target dupeNone [list $pattern]
    }
    SendTargetTheme $target dupeFoot
}

####
# New
#
# Display recent releases, command: !new [-limit <num>].
#
proc ::alcoholicz::GlData::New {command target user host handle channel argv} {
    variable structFormat

    # Parse command options.
    set option(limit) -1
    if {[catch {set pattern [GetOptions $argv {{limit integer}} option]} message]} {
        CmdSendHelp $channel channel $command $message
        return
    }
    set limit [GetResultLimit $option(limit)]
    set pattern [join $pattern]
    SendTargetTheme $target newHead

    set count 0
    if {[StructOpen "dirlog" handle]} {
        while {$count < $limit && [StructRead $handle data]} {
            if {[binary scan $data $structFormat(dirlog) status {} timeStamp userId groupId files {} bytes release]} {
                incr count
                putlog "\[$count\] $userId/$groupId at $files\F, $bytes\B for $release"
            }
        }
        StructClose $handle
    }

    if {!$count} {SendTargetTheme $target newNone}
    SendTargetTheme $target newFoot
}

####
# Search
#
# Search the dirlog for a release, command: !search [-limit <num>] <pattern>.
#
proc ::alcoholicz::GlData::Search {command target user host handle channel argv} {
    variable structFormat

    # Parse command options.
    set option(limit) -1
    if {[catch {set pattern [GetOptions $argv {{limit integer}} option]} message]} {
        CmdSendHelp $channel channel $command $message
        return
    }
    if {[set pattern [join $pattern]] eq ""} {
        CmdSendHelp $channel channel $command "you must specify a pattern"
        return
    }
    set limit [GetResultLimit $option(limit)]
    SendTargetTheme $target searchHead [list $pattern]

    set count 0
    if {[StructOpen "dirlog" handle 0]} {
        while {$count < $limit && [StructRead $handle data]} {
            if {[binary scan $data $structFormat(dirlog) status {} timeStamp userId groupId files {} bytes release]} {
                incr count
                putlog "\[$count\] $userId/$groupId at $files\F, $bytes\B for $release"
            }
        }
        StructClose $handle
    }

    if {!$count} {SendTargetTheme $target searchNone [list $pattern]}
    SendTargetTheme $target searchFoot
}

####
# Nukes
#
# Display recent nukes, command: !nukes [-limit <num>] [pattern].
#
proc ::alcoholicz::GlData::Nukes {command target user host handle channel argv} {
    # Parse command options.
    set option(limit) -1
    if {[catch {set pattern [GetOptions $argv {{limit integer}} option]} message]} {
        CmdSendHelp $channel channel $command $message
        return
    }
    set limit [GetResultLimit $option(limit)]
    set pattern [join $pattern]
    SendTargetTheme $target nukesHead

    set count 0
    if {[set handle [OpenFile "nukelog"]] ne ""} {
        # TODO:
        # - Read log file.
        # - Parse binary data with "binary scan".
        # - Output data.
        close $handle
    }

    if {!$count} {SendTargetTheme $target nukesNone}
    SendTargetTheme $target nukesFoot
}

####
# Unnukes
#
# Display recent unnukes, command: !unnukes [-limit <num>] [pattern].
#
proc ::alcoholicz::GlData::Unnukes {command target user host handle channel argv} {
    # Parse command options.
    set option(limit) -1
    if {[catch {set pattern [GetOptions $argv {{limit integer}} option]} message]} {
        CmdSendHelp $channel channel $command $message
        return
    }
    set limit [GetResultLimit $option(limit)]
    set pattern [join $pattern]
    SendTargetTheme $target unnukesHead

    set count 0
    if {[set handle [OpenFile "nukelog"]] ne ""} {
        # TODO:
        # - Read log file.
        # - Parse binary data with "binary scan".
        # - Output data.
        close $handle
    }

    if {!$count} {SendTargetTheme $target unnukesNone}
    SendTargetTheme $target unnukesFoot
}

####
# OneLines
#
# Display recent one-lines, command: !onel.
#
proc ::alcoholicz::GlData::OneLines {command target user host handle channel argv} {
    variable oneLines
    SendTargetTheme $target oneLinesHead

    set count 0
    if {[set handle [OpenFile "oneliner"]] ne ""} {
        # TODO:
        # - Read log file.
        # - Parse binary data with "binary scan".
        # - Output data.
        close $handle
    }

    if {!$count} {SendTargetTheme $target oneLinesNone}
    SendTargetTheme $target oneLinesFoot
}

####
# Load
#
# Module initialisation procedure, called when the module is loaded.
#
proc ::alcoholicz::GlData::Load {firstLoad} {
    variable logsPath
    variable structFormat
    variable structLength
    upvar ::alcoholicz::configHandle configHandle

    # For 32-bit little endian systems.
    array set structFormat {
        dirlog   ssisssswA255
        dupefile A256iA25
        nukelog  ssiA12A12A12ssfA60A255
        oneliner A24A24A64iA100
    }
    array set structLength {
        dirlog   288
        dupefile 288
        nukelog  376
        oneliner 216
    }

    # Check defined directory paths.
    set logsPath [file join [ConfigGet $configHandle Ftpd dataPath] "logs"]
    if {![file isdirectory $logsPath]} {
        error "the directory \"$logsPath\" does not exist"
    }

    if {[ConfigExists $configHandle Module::GlData cmdPrefix]} {
        set prefix [ConfigGet $configHandle Module::GlData cmdPrefix]
    } else {
        set prefix $::alcoholicz::cmdPrefix
    }

    # Directory commands.
    CmdCreate channel dupe   [namespace current]::Dupe \
        -category "Data"  -args "\[-limit <num>\] <pattern>" \
        -prefix   $prefix -desc "Search the dupe database for a release."

    CmdCreate channel new    [namespace current]::New \
        -category "Data"  -args "\[-limit <num>\] \[pattern\]" \
        -prefix   $prefix -desc "Display new releases."

    CmdCreate channel search [namespace current]::Search \
        -category "Data"  -args "\[-limit <num>\] <pattern>" \
        -prefix   $prefix -desc "Search the site for a release."

    # Nuke commands.
    CmdCreate channel nukes   [namespace current]::Nukes \
        -category "Data"  -args "\[-limit <num>\] \[pattern\]" \
        -prefix   $prefix -desc "Display recent nukes."

    CmdCreate channel unnukes [namespace current]::Unnukes \
        -category "Data"  -args "\[-limit <num>\] \[pattern\]" \
        -prefix   $prefix -desc "Display recent unnukes."

    # Other commands.
    CmdCreate channel onel    [namespace current]::OneLines \
        -category "General" -desc "Display recent one-lines." -prefix $prefix
}

####
# Unload
#
# Module finalisation procedure, called before the module is unloaded.
#
proc ::alcoholicz::GlData::Unload {} {
}
