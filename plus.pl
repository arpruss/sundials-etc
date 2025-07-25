#!/usr/bin/perl -w
#
#
#Copyright 2011-13 Alexander R. Pruss. All rights reserved.
#
#Redistribution and use in source and binary forms, with or without modification, are
#permitted provided that the following conditions are met:
#
#   1. Redistributions of source code must retain the above copyright notice, this list of
#      conditions and the following disclaimer.
#
#   2. Redistributions in binary form must reproduce the above copyright notice, this list
#      of conditions and the following disclaimer in the documentation and/or other materials
#      provided with the distribution.
#
#THIS SOFTWARE IS PROVIDED BY <COPYRIGHT HOLDER> ''AS IS'' AND ANY EXPRESS OR IMPLIED
#WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
#FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> OR
#CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
#ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
#NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#The views and conclusions contained in the software and documentation are those of the
#authors and should not be interpreted as representing official policies, either expressed
#or implied, of Alexander R. Pruss.
#

use CGI;
#use CGI::Carp qw(fatalsToBrowser);
use PDF::Create;

use constant mm => 72 / 25.4;
use constant in => 72;
use constant pt => 1;

$lineWidth = 0.25;
$holesPerRow = 3;
$holesPerCol = 4;
$cardsPerRow = 3;
$roundedFraction = 0.1; # fraction of cardWidth
$diagFraction = 0.07;
$shape = "r";

if (@ARGV>=2) {
    $holeCols = $ARGV[0];
    $holeRows = $ARGV[1];
    $cardsPerRow = $ARGV[2] if @ARGV>=3;
}
else {
    $query = new CGI;
    $go = get($query, "Go", 0);

    if (!$go) {
        print $query->header(-expires=>'now', -type=>"text/html");
        print "<html><title>Plus Card Game Generator</title>\n";
        print "<body><form action='plus.pl' method='get'>\n";
        print "<p>Slots on each card: ";
        numeric_form("cols",2,6,3);
        print " x ";
        numeric_form("rows",2,6,4);
        print "</p>\n";
        print "<p>How many cards to print in each row on the page? ";
        numeric_form("cardsPerRow",2,6,3);
        print "</p>\n";
        print "<p>Card shape? ";

        print "<select name='shape'>\n";
        print " <option value='o'>octagonal</option>\n";
        print " <option selected='1' value='r'>rounded</option>\n";
        print " <option value='s'>square</option>\n";
        print "</select></p>\n";
        print "<input type='submit' name='Go' value='Go'/>\n";
        print "</form></body></html>\n";
        exit 0;
    }
    else {
        $mimetype='application/pdf';
        print $query->header(-expires=>'now', -type=>$mimetype,
           -disposition=>"inline:filename=plus.pdf", -filename=>'plus.pdf');
#        $roundedFraction = get($query, "roundedFraction", $roundedFraction);
        $shape = get($query, "shape", "r");
        $lineWidth = get($query, "lineWidth", $lineWidth);
        $holesPerRow = get($query, "cols", $holeCols);
        $holesPerCol = get($query, "rows", $holeRows);
        $cardsPerRow = get($query, "cardsPerRow", $cardsPerRow);
    }
}


@hole = ( 0.5, 0,
          1, 0.5,
          0.5, 1,
          0, 0.5,
          0.5, 0 );

$delta = 0.1;

@vert = ( 0.5+$delta, $delta,
          1, 0.5,
          0.5+$delta, 1-$delta,
          0.5+$delta, $delta,
          -1, -1,
          0.5-$delta, $delta,
          0, 0.5,
          0.5-$delta, 1-$delta,
          0.5-$delta, $delta );

$holesPerRow = 1 if $holesPerRow < 1;
$holesPerRow = 6 if $holesPerRow > 6;
$holesPerCol = 2 if $holesPerCol < 2;
$holesPerCol = 6 if $holesPerCol > 6;
$cardsPerRow = 1 if $cardsPerRow < 1;

$paperWidth = 8.5 * in;
$paperHeight = 11 * in;
$margin = 0.5 * in;

$usableWidth = $paperWidth - 2*$margin;
$usableHeight = $paperHeight - 2*$margin;

$holeMarginFrac = 0.3;

$cardWidth = $usableWidth / $cardsPerRow;
$holeSize = $cardWidth / ($holesPerRow * (1 + $holeMarginFrac) + $holeMarginFrac);
$cardHeight = $holeSize * ($holesPerCol * (1 + $holeMarginFrac) + $holeMarginFrac);
$cardsPerCol = int($usableHeight / $cardHeight);
$cardsPerCol = 1 if $cardsPerCol < 1;
$roundedSize = ($shape eq "o") ? ($cardWidth * $diagFraction ): ($cardWidth * $roundedFraction);

#$pdf = PDF::API2->new();

$pdf = new PDF::Create('filename' => '-',
			      'Version'  => 1.2,
			      'Author'   => 'Alex Pruss',
			      'Title'    => 'plus cards',
			 );
$root = $pdf->new_page('MediaBox'  => [ 0, 0, $paperWidth, $paperHeight ]);
#$root->set_width($lineWidth);

$x = 0;
$y = 0;

for $posVer (0..($holesPerRow * $holesPerCol - 1)) {
    for $posHor (($posVer+1)..($holesPerRow * $holesPerCol - 1)) {
         if ($x == 0 && $y == 0) {
             $page = $root->new_page;
             $page->set_width($lineWidth);
         }

         $verX = $posVer % $holesPerRow;
         $verY = int($posVer / $holesPerRow);

         $horX = $posHor % $holesPerRow;
         $horY = int($posHor / $holesPerRow);

         generateCard();

         $x++;

         if ($x >= $cardsPerRow) {
             $x = 0;
             $y++;
         }

         if ($y >= $cardsPerCol) {
             $x = 0;
             $y = 0;
         }
    }
}

#binmode(STDOUT);
$pdf->close;

exit 0;


sub generateCard {
    my $llX = $x * $cardWidth + $margin;
    my $llY = ($cardsPerCol - 1 - $y) * $cardHeight + $margin;

    $page->newpath;
    if ($shape eq "s") {
        $page->moveto($llX, $llY);
        $page->lineto($llX, $llY+$cardHeight);
        $page->lineto($llX+$cardWidth, $llY+$cardHeight);
        $page->lineto($llX+$cardWidth, $llY);
        $page->closepath;
    }
    else {
        quarter($page, $llX, $llY, $roundedSize, 0, 0, $roundedSize, $shape);
        $page->lineto($llX, $llY+$cardHeight-$roundedSize);
        quarter($page, $llX, $llY+$cardHeight, 0, -$roundedSize, $roundedSize, 0, $shape);
        $page->lineto($llX+$cardWidth-$roundedSize, $llY+$cardHeight);
        quarter($page, $llX+$cardWidth, $llY+$cardHeight, -$roundedSize, 0, 0, -$roundedSize, $shape);
        $page->lineto($llX+$cardWidth, $llY+$roundedSize);
        quarter($page, $llX+$cardWidth, $llY, 0, $roundedSize, -$roundedSize, 0, $shape);
        $page->lineto($llX+$roundedSize, $llY);
    }
    $page->stroke;

    $page->newpath;
    for my $col (0..($holesPerRow - 1)) {
        for my $row (0..($holesPerCol - 1)) {
             my $lX = $llX + ($col * (1 + $holeMarginFrac) + $holeMarginFrac) * $holeSize;
             my $lY = $llY + ($row * (1 + $holeMarginFrac) + $holeMarginFrac) * $holeSize;
             if ($col == $verX && $row == $verY) {
                 draw($page, $lX, $lY, \@vert, 0);
             }
             elsif ($col == $horX && $row == $horY) {
                 draw($page, $lX, $lY, \@vert, 1);
             }
             else {
                 draw($page, $lX, $lY, \@hole, 0);
             }
        }
    }
    $page->closepath;
    $page->stroke;
}



sub draw {
    my $page = shift;
    my $lX = shift;
    my $lY = shift;
    my $pointsR = shift;
    my @points = @{$pointsR};
    my $flip = shift;

    my $move = 1;

    for ($i = 0; $i < @points ; $i+=2) {
         my $x;
         my $y;

         if ($points[$i] == -1 && $points[$i+1] == -1) {
             $move = 1;
         }
         else {
             if ($flip) {
                 $x = $points[$i+1];
                 $y = $points[$i];
             }
             else {
                 $x = $points[$i];
                 $y = $points[$i+1];
             }

             if ($move) {
                 $page->moveto(round($lX+$x*$holeSize),round($lY+$y*$holeSize));
                 $move = 0;
             }
             else {
                 $page->lineto(round($lX+$x*$holeSize),round($lY+$y*$holeSize));
             }
         }
    }
}

sub quarter {
    my $page = shift;
    my $x0 = shift;
    my $y0 = shift;
    my $dx1 = shift;
    my $dy1 = shift;
    my $dx2 = shift;
    my $dy2 = shift;
    my $c = 0.55191502449;
    my $shape = shift;

    $page->moveto($x0+$dx1,$y0+$dy1);
    if ($shape eq "r") {
        $page->curveto($x0+$dx1*(1-$c),$y0+$dy1*(1-$c),
                       $x0+$dx2*(1-$c),$y0+$dy2*(1-$c),
                       $x0+$dx2,$y0+$dy2);
    }
    else {
        $page->lineto($x0+$dx2,$y0+$dy2);
    }
}

sub get {
    my $query = shift;
    my $name = shift;
    my $default = shift;

    my $a = $query->param($name);
    return $a if defined($a);
    return $default;
}


sub round {
    my $x = shift;
    return int($x*1000)/1000.;
}


sub numeric_form {
    my $name = shift;
    my $start = shift;
    my $stop = shift;
    my $default = shift;

    print "<select name='$name'>\n";
    for my $i ($start..$stop) {
        print " <option ";
        print "selected='1' "if ($i==$default);
        print "value='$i'>$i</option>\n";
    }
    print "</select>\n";
}
