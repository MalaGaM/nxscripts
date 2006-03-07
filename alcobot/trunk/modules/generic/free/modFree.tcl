#
# AlcoBot - Alcoholicz site bot.
# Copyright (c) 2005-2006 Alcoholicz Scripting Team
#
# Module Name:
#   Free Module
#
# Author:
#   neoxed (neoxed@gmail.com) Aug 25, 2005
#
# Abstract:
#   Implements a module to display available drive space.
#

namespace eval ::Bot::Free {
    if {![info exists [namespace current]::volumeList]} {
        variable volumeList [list]
    }
    namespace import -force ::Bot::*
}

####
# Command
#
# Implements a channel command to display available drive space.
#
proc ::Bot::Free::Command {target user host channel argv} {
    variable volumeList

    set argc [llength $argv]
    if {$argc > 1} {throw CMDHELP}

    # Only display the header and footer if no section was specified.
    if {!$argc} {
        SendTargetTheme $target freeHead
    }

    set count 0; set free 0; set used 0; set total 0
    foreach {volume sections} $volumeList {
        if {$argc && ![ListExists $sections [lindex $argv 0]]} {continue}

        if {[catch {volume info $volume info} message]} {
            LogError ModFree $message; continue
        }
        if {$info(total) == 0} {
            LogError ModFree "Invalid volume \"$volume\": the total size is zero."
            continue
        }

        set percentFree [expr {(double($info(free)) / double($info(total))) * 100.0}]
        set percentUsed [expr {(double($info(used)) / double($info(total))) * 100.0}]

        SendTargetTheme $target freeBody [list $info(free) $info(used) $info(total) \
            $percentFree $percentUsed [join $sections]]

        # Update volume totals.
        incr count
        set free [expr {wide($free) + $info(free)}]
        set used [expr {wide($used) + $info(used)}]
        set total [expr {wide($total) + $info(total)}]
    }

    if {!$argc} {
        if {$total} {
            set percentFree [expr {(double($free) / double($total)) * 100.0}]
            set percentUsed [expr {(double($used) / double($total)) * 100.0}]
        } else {
            set percentFree 0.0; set percentUsed 0.0
        }

        SendTargetTheme $target freeFoot [list $free $used $total \
            $percentFree $percentUsed $count]
    }
}

####
# Load
#
# Module initialisation procedure, called when the module is loaded.
#
proc ::Bot::Free::Load {firstLoad} {
    variable volumeList
    upvar ::Bot::configHandle configHandle

    set volumeList [list]
    foreach {name value} [Config::GetEx $configHandle Module::Free] {
        lappend volumeList $name $value
    }

    CmdCreate channel free [namespace current]::Command \
        -category "General" \
        -aliases "df" \
        -args "\[section\]" \
        -desc "Display free disk space."
}

####
# Unload
#
# Module finalisation procedure, called before the module is unloaded.
#
proc ::Bot::Free::Unload {} {
}
