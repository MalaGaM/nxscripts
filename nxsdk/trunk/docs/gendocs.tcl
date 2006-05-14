#
# nxSDK - ioFTPD Software Development Kit
# Copyright (c) 2006 neoxed
#
# Module Name:
#   Gen Docs
#
# Author:
#   neoxed (neoxed@gmail.com) May 13, 2006
#
# Abstract:
#   Generates source documentation.
#

# Base directory to change to.
set baseDir ".."

# Location of the input files.
set inputFiles {
    "src/nxsdk.h"
    "src/lib/*.c"
    "src/lib/*.h"
}

################################################################################

proc BufferFile {path} {
    set handle [open $path "r"]
    set data [read $handle]
    close $handle
    return $data
}

proc ParseText {text} {
    set status 0
    set result [list]

    foreach line [split $text "\n"] {
        set line [string trimright $line]

        # status values:
        # 0 - Ignore the line.
        # 1 - In a marked block comment (/*++ ... --*/).
        # 2 - After the end of a block comment.

        if {$line eq "/*++"} {
            if {$status == 2} {
                lappend result $desc $code
                set code [list]
                set desc [list]
                set status 0
            } elseif {$status == 1} {
                puts "    - Found comment start but we are already in a comment block."
            } else {
                set status 1
                set code [list]
                set desc [list]
            }

        } elseif {$line eq "--*/"} {
            if {$status != 1} {
                puts "    - Found comment end but we are not in a comment block."
            } else {
                set status 2
            }

        } elseif {$status == 2} {
            if {$line eq ""} {
                lappend result $desc $code
                set code [list]
                set desc [list]
                set status 0
            } else {
                lappend code $line
            }

        } elseif {$status == 1} {
            lappend desc $line
        }
    }

    return $result
}

################################################################################

proc ListTrim {items} {
    # Remove empty leading elements.
    while {[llength $items] && [lindex $items 0] eq ""} {
        set items [lreplace $items 0 0]
    }

    # Remove empty trailing elements.
    while {[llength $items] && [lindex $items end] eq ""} {
        set items [lreplace $items end end]
    }
    return $items
}

proc ListToArgs {items} {
    # Group arguments.
    set count 0
    foreach line [ListTrim $items] {
        set line [string trimleft $line]

        if {[regexp -- {^(\w+)\s+-\s+(.+)$} $line dummy name line]} {
            incr count
            lappend arg($count) $name $line
        } elseif {$count} {
            lappend arg($count) $line
        } else {
            puts "    - Found argument description before definition."
        }
    }

    # Format the result: argOne {paraOne paraTwo} argTwo {paraOne paraTwo} ...
    set count 1
    set result [list]
    while {[info exists arg($count)]} {
        set name [lindex $arg($count) 0]
        set text [lrange $arg($count) 1 end]
        lappend result $name [ListToText $text]
        incr count
    }
    return $result
}

proc ListToText {items} {
    # Group paragraphs.
    set count 0
    foreach line [ListTrim $items] {
        set line [string trimleft $line]

        if {$line eq ""} {
            incr count
        } else {
            lappend para($count) $line
        }
    }

    # Format the result: paraOne paraTwo paraThree ...
    set count 0
    set result [list]
    while {[info exists para($count)]} {
        lappend result [join $para($count)]
        incr count
    }
    return $result
}

################################################################################

proc WriteHeader {handle title} {
    puts $handle "<html>"
    puts $handle "<head>"
    puts $handle "  <title>$title</title>"
    puts $handle {
  <style>
    body {
      font-family:verdana,arial,helvetica;
      margin:0;
    }
  </style>

  <link rel="stylesheet" type="text/css" href="default.css" />
  <link rel="stylesheet" type="text/css" href="ie4.css" />
  <link rel="stylesheet" type="text/css" href="ie5.css" />
</head>

<body topmargin="0" leftmargin="0" marginheight="0" marginwidth="0" bgcolor="#FFFFFF" text="#000000">
<table class="clsContainer" cellpadding="10" cellspacing="0" float="left" width="100%" border="1">
}
}

proc WriteEntry {handle name link content} {
    puts $handle "<!-- Start $name -->"
    puts $handle "<tr>"
    puts $handle "<td valign=\"top\">"
    puts $handle "<h1><a name=\"$link\"></a>$name</h1>"
    puts $handle $content
    puts $handle "</td>"
    puts $handle "</tr>"
    puts $handle "<!-- End $name -->"
    puts $handle ""
}

proc WriteFooter {handle} {
    puts $handle "</table>"
    puts $handle "</body>"
    puts $handle "</html>"
}

################################################################################

puts "\n\tGenerating Source Documents\n"

puts "- Changing to base directory"
set currentDir [pwd]
cd $baseDir

puts "- Reading source files"
set funcList [list]
set structList [list]

foreach pattern $inputFiles {
    foreach path [glob -nocomplain $pattern] {
        puts "  - Reading file: $path"

        foreach {desc code} [ParseText [BufferFile $path]] {
            # Count and remove outer empty lines.
            set beforeCount [llength $desc]
            set desc [ListTrim $desc]
            set afterCount [llength $desc]

            if {!$afterCount} {
                puts "    - Empty comment block."
                continue
            }
            set diffCount [expr {$beforeCount - $afterCount}]
            if {$diffCount != 2} {
                puts "    - Found $diffCount outer empty lines in a comment block, should be 2 empty lines."
            }

            # Detect function and structure comments.
            if {[lsearch -exact $desc "Arguments:"] != -1 && [lsearch -exact $desc "Return Values:"] != -1} {
                lappend funcList $desc $code

            } elseif {[lsearch -exact $desc "Members:"] != -1} {
                lappend structList $desc $code

            } else {
                set sections [join [lsearch -all -inline -regexp $desc {^[\s\w]+:$}] {, }]
                puts "    - Unknown comment type, sections are \"$sections\"."
            }
        }
    }
}

puts "- Changing back to original directory"
cd $currentDir

################################################################################

puts "- Parsing data"
unset -nocomplain funcs structs

foreach {desc code} $funcList {
    set name [lindex $desc 0]
    puts "  - Function: $name"

    if {![string is wordchar -strict $name]} {
        puts "    - Invalid function name, skipping."
        continue
    }
    if {[info exists funcs($name)]} {
        puts "    - Function already defined, skipping."
        continue
    }

    set section "intro"
    array set text [list intro "" args "" remarks "" retvals ""]
    foreach line [lrange $desc 1 end] {
        switch -regexp -- $line {
            {^Arguments:$}    {set section "args"}
            {^Remarks:$}      {set section "remarks"}
            {^Return Values:$} {set section "retvals"}
            {^[\s\w]+:$}      {puts "    - Unknown comment section \"$line\"."}
            default           {lappend text($section) $line}
        }
    }

    set text(intro)   [ListToText $text(intro)]
    set text(args)    [ListToArgs $text(args)]
    set text(remarks) [ListToText $text(remarks)]
    set text(retvals) [ListToText $text(retvals)]

    set link "[string tolower $name]_func"
    set funcs($name) [list $link $text(intro) $text(args) $text(remarks) $text(retvals)]
}

foreach {desc code} $structList {
    set name [lindex $desc 0]
    puts "  - Structure: $name"

    if {![string is wordchar -strict $name]} {
        puts "    - Invalid structure name, skipping."
        continue
    }
    if {[info exists structs($name)]} {
        puts "    - Structure already defined, skipping."
        continue
    }

    set section "intro"
    array set text [list intro "" members "" remarks ""]
    foreach line [lrange $desc 1 end] {
        switch -regexp -- $line {
            {^Members:$} {set section "members"}
            {^Remarks:$} {set section "remarks"}
            {^[\s\w]+:$} {puts "    - Unknown comment section \"$line\"."}
            default      {lappend text($section) $line}
        }
    }

    set text(intro)   [ListToText $text(intro)]
    set text(members) [ListToArgs $text(members)]
    set text(remarks) [ListToText $text(remarks)]

    set link "[string tolower $name]_struct"
    set structs($name) [list $link $text(intro) $text(members) $text(remarks)]
}

################################################################################

puts "- Transforming data"

set funcLinks [list]
set funcNames [lsort [array names funcs]]
set structLinks [list]
set structNames [lsort [array names structs]]

foreach name $funcNames {
    set link [lindex $funcs($name) 0]
    lappend funcLinks $name $link
    lappend funcLinkMap $name "functions.htm#$link"
}

foreach name $structNames {
    set link [lindex $structs($name) 0]
    lappend structLinks $name $link
    lappend structLinkMap $name "structures.htm#$link"
}

################################################################################

puts "- Writing functions"

set handle [open "functions.htm" "w"]
WriteHeader $handle "Functions"

foreach name $funcNames {
    foreach {link intro args remarks retvals} $funcs($name) {break}
    WriteEntry $handle $name $link TODO
}

WriteFooter $handle
close $handle

puts "- Writing structures"
set handle [open "structures.htm" "w"]
WriteHeader $handle "Structures"

foreach name $structNames {
    foreach {link intro members remarks} $structs($name) {break}
    WriteEntry $handle $name $link TODO
}

WriteFooter $handle
close $handle

puts "- Finished"
return 0
