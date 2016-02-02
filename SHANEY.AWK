#----------------------------------------------------------------------------
# SHANEY.AWK
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# Initialization
#----------------------------------------------------------------------------

BEGIN {

   FALSE = 0
   TRUE = 1
   LINEMAX = 72

   strOne = ""
   strTwo = ""

   srand()
}

#----------------------------------------------------------------------------
# Actions for every line
#----------------------------------------------------------------------------

{
   local i

#print "Line: " $0

   if( NF )
      for( i = 1;  i <= NF;  i++ )
         SaveWord( $i )
   else if( strTwo != "\n" )
      SaveWord( "\n" )
}

#----------------------------------------------------------------------------
# End of input - write output
#----------------------------------------------------------------------------

END {

   words[strOne,strTwo] = ""

   linelen = 0

   strOne = ""
   strTwo = ""

   while( TRUE ) {

      count = split( words[strOne,strTwo], nextwords, SUBSEP )

      word = nextwords[ int( rand() * (count-1) ) + 2 ]

      if( word == "" ) {
         FlushLine()
         exit
      }

      PrintWord( word )

      strOne = strTwo
      strTwo = word
   }

   FlushLine()
}

#----------------------------------------------------------------------------
# Save a word
#----------------------------------------------------------------------------

function SaveWord( word ) {

   words[strOne,strTwo] = words[strOne,strTwo] SUBSEP word

#print "words[" strOne "," strTwo "] = " words[strOne,strTwo]

   strOne = strTwo
   strTwo = word
}

#----------------------------------------------------------------------------
# Print a word
#----------------------------------------------------------------------------

function PrintWord( word ) {

   if( word == "\n" ) {
      FlushLine()
      print
      return
   }

   len = length( word ) + 1

   if( linelen + len > LINEMAX )
      FlushLine()

   if( linelen )
      strLine = strLine " "

   strLine = strLine word
   linelen += len
}

#----------------------------------------------------------------------------
# Flush the current line
#----------------------------------------------------------------------------

function FlushLine() {

   if( linelen )
      print strLine

   linelen = 0
   strLine = ""
}

#----------------------------------------------------------------------------
