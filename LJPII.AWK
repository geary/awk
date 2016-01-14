#----------------------------------------------------------------------------
# LJP.AWK - sideways listing program for HP LaserJet II
#----------------------------------------------------------------------------
# Copyright 1991 Michael Geary.  All rights reserved.
#----------------------------------------------------------------------------
# LJP is a source code listing program that prints two 60-line pages of
# source code on each page of paper. It prints the pages sideways using the
# "line printer" internal LaserJet font, with a box around each page and
# graphic separators replacing the rows of dashes or stars commonly used in
# source code to mark off sections of code. It uses a smart page break
# algorithm: if a separator line is preceded by a blank line, that marks a
# preferred page break point. Empty space at the end of a page is filled
# in with a light dot pattern.
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# LaserJet II driver functions
#----------------------------------------------------------------------------

function Gray( x, y, percent ) {
    printf "\033*c%da%dbc%dg2P", x, y, percent
}

function Line( x, y ) { printf "\033*c%da%dbc0P", x, y }

function ResetPrinter() { printf "\033E" }

function SetLandscape() { printf "\033&l1O" }

function SetLeftMargin( margin ) { printf "\033&a%dL", margin }

function SetNoMargins() { printf "\0339" }

function SetPica() { printf "\033&l8C\033(s10h" }

function SetPortrait() { printf "\033&l0O" }

function SetTiny() { printf "\033&l6C\033(s16.66h" }

function SetXY( x, y ) {
    printf "\033*p%dx%dY", x + xLeft, y + yTop
}

function Shade( x, y, cx, cy, lw ) {
    SetXY( x + lw, y + lw )
    Gray( cx - lw*2, cy - lw*2, 2 )
}

#----------------------------------------------------------------------------
# Print one page box.
#----------------------------------------------------------------------------

function PrintBox( x, y ) {
    # top border
    SetXY( x, y )
    Line( xPage, LW )

    # bottom border
    SetXY( x, y + yPage - LW )
    Line( xPage, LW )

    # left border
    SetXY( x, y + LW )
    Line( LW, yPage - LW*2 )

    # right border
    SetXY( x + xPage - LW, y + LW )
    Line( LW, yPage - LW*2 )
}

#----------------------------------------------------------------------------
# Draw the page frame and print file info.
# Handles both left and right pages.
#----------------------------------------------------------------------------

function PrintFrame( fLastPage ) {
    if( nCurPage % 2 ) {
        # left page: print frame for both pages, left page number, file info
        PrintBox( 0, 0 )
        PrintBox( xPage + xGutter, 0 )

        SetXY( 0, yTitleBoxText )
        printf "Page %d", nCurPage

        SetXY( 920 - ( length(strFileName)+6 )*xChar/2, yTitleBoxText )
        printf "File: %s", strFileName

        SetXY( 1875, yTitleBoxText )
        if( strFileDate != "" )
            printf "Last Modified: %s", strFileDate

        #  Printer doesn't like being switched between orientations
        #  SetXY( xPage*2+xGutter+(??), 0 )
        #  SetXY( xPage*2+xGutter, 0 )
        #  SetPortrait()
        #  printf "%125s", strFileName "  Page " nCurPage
        #  SetLandscape()

        if( fLastPage ) {
            # there won't be a right page
            Shade( xPage+xGutter, 0, xPage, yPage, LW+2 )
            printf "\f"
        }
    } else {
        # right page: print right page number and eject page
        SetXY( xPage*2 + xGutter - 180, yTitleBoxText )
        printf "%10s", "Page " nCurPage
        printf "\f"
    }
}

#----------------------------------------------------------------------------
# Print the current page (logical page, that is - this function is called
# twice per printed page, for the left and right sides).
#----------------------------------------------------------------------------

function PrintPage( fLastPage,  x, y, nLine ) {
    if( ! nCurLine )
        return

    if( fLastPage )
        nBreakLine = nCurLine + 1
    else if( nBreakLine == nFirstLine )
        nBreakLine = nFirstLine + nLinesPerPage

    nCurPage++

    x = 0  # left page
    if( ! ( nCurPage % 2 ) )
        x = xPage + xGutter  # right page

    y = 0

    for( nLine = nFirstLine;  nLine < nBreakLine;  nLine++ ) {
        if( ! afBreak[nLine] ) {
            SetXY( x + xText, y + yText )
            printf "%s", strLine[nLine]
        } else if( nLine > nFirstLine ) {
            SetXY( x + LW, y + 40 )
            Line( xPage - LW*2, LW )
        } else {
            y -= yChar
        }

        delete afBreak[nLine]
        delete strLine[nLine]

        y += yChar
    }

    if( nBreakLine < nFirstLine + nLinesPerPage ) {
        SetXY( x + LW, y + 40 )
        Line( xPage - LW*2, LW )
        Shade( x, y+40, xPage, yPage-y-40, LW+2 )
    }

    nFirstLine = nBreakLine

    PrintFrame( fLastPage )
}

#----------------------------------------------------------------------------
# Fetch the information about the current file for printing later
#----------------------------------------------------------------------------

function GetFileInfo() {
    system( "listdir " FILENAME ">lister~.tmp" )

    getline strFileName <"lister~.tmp"
    getline strFileDate <"lister~.tmp"

    close( "lister~.tmp" )

    system( "erase lister~.tmp" )
}

#----------------------------------------------------------------------------
# Initialization
#----------------------------------------------------------------------------

BEGIN {
    FALSE = 0
    TRUE = 1

    LW = 3  # Line Width

    xLeft = 10  # Left offset
    yTop = 40  # Top offset

    xPage = 1540  # Width of page box
    yPage = 2260  # Height of page box

    xGutter = 70  # Space between pages

    yTitleBox = -40
    cyTitleBox = 35
    yTitleBoxText = -30

    xText = 35
    yText = 50

    xChar = 18
    yChar = 37

    nLinesPerPage = 60
    nCharsPerLine = 80

    ResetPrinter()
    SetLandscape()
    SetTiny()
}

#----------------------------------------------------------------------------
# Processing for first line of each file
#----------------------------------------------------------------------------

FNR == 1 {
    if( NR > 1 )
        PrintPage( TRUE )  # not first file, flush previous

    GetFileInfo()

    print "Printing " strFileName >"con"
    close( "con" )

    nFirstLine = 1
    nBreakLine = 1
    nCurLine = 0
    nCurPage = 0

    fPrevBlank = FALSE
}

#----------------------------------------------------------------------------
# Detab any lines containing tabs
#----------------------------------------------------------------------------

index( $0, "\t" ) {  # MKS AWK bug: simple pattern of /\t/ doesn't work!
    tab = 8
    blanks = "        "

    s = $0

    while( col = index( s, "\t" ) ) {
        s = substr(s,1,col-1) substr(blanks,(col-1)%tab+1) substr(s,col+1)
    }

    $0 = s
}

#----------------------------------------------------------------------------
# Pattern matching for separator lines.  A separator line is any line that
# is 20 characters or longer and contains only these characters:
#
#   - !  # $ % * / ; = \ _ | (space - but not two spaces in a row)
#
# This is somewhat arbitrary, but catches the separator lines and boxes
# commonly used in source code.
#
# Separator lines are replaced by horizontal lines in the printout.  If a
# separator line is preceded by a blank line, that marks a preferred page
# break point.
#----------------------------------------------------------------------------

/^[- !#$%*\/;=\\_|]+$/  {
    if( length($0) >= 20  &&  $0 !~ /  / ) {
        afBreak[nCurLine+1] = TRUE
        if( fPrevBlank )
            nBreakLine = nCurLine + 1
    }
}

#----------------------------------------------------------------------------
# Actions taken for every input line
#----------------------------------------------------------------------------

{
    fPrevBlank = ( $0 == "" )

    # while( sub( /\f/, "" ) )
    #     nBreakLine = nCurLine + 1

    while( i = index( $0, "\f" ) ) {
        $0 = substr( $0, 1, i-1 ) substr( $0, i+1 )
        nBreakLine = nCurLine + 1
    }

    while( length($0) > nCharsPerLine ) {
        # too long, split
        strLine[++nCurLine] = substr( $0, 1, nCharsPerLine ) "\277"
        $0 = substr( $0, nCharsPerLine+1 )
    }

    strLine[++nCurLine] = $0

    if( nCurLine - nFirstLine >= nLinesPerPage )
        PrintPage( FALSE )
}

#----------------------------------------------------------------------------
# Termination
#----------------------------------------------------------------------------

END {
    PrintPage( TRUE )

    SetPortrait()
    SetTiny()
    SetNoMargins()
    SetLeftMargin( 9 )
}

#----------------------------------------------------------------------------
