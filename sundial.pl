#!/usr/bin/perl -w
#
#
#Copyright 2011 Alexander R. Pruss. All rights reserved.
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
use Math::Trig;
use PDF::Create;
use POSIX qw(ceil floor);
use Fcntl qw(:seek);

LoadTZNames();

undef($invalid);
$dstMode = "none";
$instructions = 1;
$numerals = "arabic";

if (@ARGV>0) {
   $tz = -5;
   $longitudeEast = -(97+8/60.);
   $latitude = 31 + 33/60.;
   $officialWidth = 200;
   $unit = "cm";
   $location = "Waco";

   while(@ARGV) {
       $_ = shift @ARGV;

       if (/tz=(.*)$/) {
           Usage() if !ParseTZ($1);
       }
       elsif (/xy=(.*)$/) {
           $xy = $1;
       }
       elsif (/dst=(summer|winter|none)/) {
           $dstMode = $1;
       }
       elsif (/lon=(.*)$/) {
           $longitudeEast = ParseLonLat($1, "[eE]", "[wW]");
           Usage() if !defined($longitudeEast);
       }
       elsif (/lat=(.*)$/) {
           $latitude = ParseLonLat($1, "[nN]", "[sS]");
           Usage() if !defined($latitude);
       }
       elsif (/zip=(.*)$/) {
           GetLonLatByZip($1);
           Usage() if !defined($latitude);
       }
       elsif (/size=(.*)$/) {
           Usage() if !ParseSize($1);
       }
       elsif (/num=(roman|romaniiii|romaniv|arabic)$/) {
           $numerals = $1;
       }
       elsif (/loc=(.*)/) {
           $location = $1;
       }
       elsif (/instructions=(.*)/) {
           $instructions = $1;
       }
       else {
           Usage();
       }
   }
   
   if ($dstMode eq "summer") {
       $tz++;
   }
}
else {
   $query = new CGI;

   if (!defined($query->param('go'))) {
       @lt = localtime(time);
       if($lt[8]) {
           $summerCheck = "checked";
           $winterCheck = "";
       }
       else {
           $winterCheck = "checked";
           $summerCheck = "";
       }
       print <<END
Content-Type: text/html

<html>
<title>Analemmatic Sundial PDF Generator</title>
<body bgcolor='#C6DEFF'>
<h1>Analemmatic Sundial PDF Generator</h1>

<p>Detailed instructions for using this script are given in
<a href="http://www.instructables.com/id/Large-driveway-sidewalk-or-garden-sundial/">my
Instructable</a> for it.</p>
<p>For a small, paper sundial project, go <a href="http://www.instructables.com/id/15-minute-paper-craft-sundial/">here</a>.</p>

<h2>Enter location parameters</h2>

<p>You must enter the width of the sundial you wish to build, enter either a zip code or
latitude/longitude, and select your timezone and daylight savings option.  Required options are in bold.</p>
<form action="sundial.pl">
<b>Sundial width: <input type="text" name="width" size=20/><select name="unit">
<option value='ft'>ft</option>
<option value='in'>in</option>
<option value='mm'>mm</option>
<option value='cm' selected>cm</option></select></b><br/>
<b>Zip code: <input type="text" name="zip" size=20/>
<em>or</em> Latitude: <input type="text" name="lat" size=20/> and Longitude: <input type="text" name="lon" size=20/><br/>
Time zone: <select name="tz">
END
       ;
       MakeTZList();
       print <<END
</select></b><br/>
<b>Daylight savings:<br/>
<input type="radio" name="dst" value="none">No daylight savings at my location</input><br/>
<input type="radio" name="dst" value="summer" $summerCheck>Put summer time on sundial</input><br/>
<input type="radio" name="dst" value="winter" $winterCheck>Put winter time on sundial</input></b><br/>
Numerals: <select name="num">
<option value='arabic' selected>Arabic</option>
<option value='roman'>Roman (4=IV)</option>
<option value='romaniiii'>Roman (4=IIII)</option>
</select><br/>
<input type="checkbox" name="xy" value="1">Include (x,y) coordinates of hour points</input><br/>
Location name: <input type="text" name="loc" size=30/> (e.g., "Paris" or "My backyard")<br/>
<input type="checkbox" name="instructions" value="1" checked>Include dimensions and instructions</input><br/>
<input type="submit" name="go" value="Go!"/>
</form>
<h2>Source code and references</h2>
<p>The source code for this perl script is available <a href="http://github.com/arpruss/sundials-etc">here</a>.  You need to get sundial.pl and zipcodes.dat, and keep them in the same directory.  You will also need the
<a href="http://search.cpan.org/~markusb/PDF-Create-1.06/lib/PDF/Create.pm">PDF::Create</a> perl package.</p>
<p>I used formulae from
<a href="http://plus.maths.org/content/os/issue11/features/sundials/index">here</a> and
<a href="http://www.ips.gov.au/Category/Educational/The%20Sun%20and%20Solar%20Activity/General%20Info/EquationOfTime.pdf">here</a>.</p>
<h2>Copyright</h2>
<p>The script (not including PDF::Create) is copyright (c) 2011 Alexander R. Pruss, and is available under the MIT license.</a>.  Alexander R. Pruss hereby releases into the public domain any and all
copyrightable visual elements in the output.  Courtesy suggests, though the law may not require,
that credit be given for use of the script when you use its output.</p>
</body>
</html>
END
;
       exit;
   }
   else {
       $mimetype='application/pdf';
       print $query->header(-expires=>'now', -type=>$mimetype,
          -disposition=>"inline:filename=sundial.pdf", -filename=>'sundial.pdf');

       undef($latitude);
       undef($longitudeEast);

       ParseTZ($query->param('tz'));
       $lon = $query->param('lon');
       $lat = $query->param('lat');
       if ($lon ne "" && $lat ne "") {
           $longitudeEast = ParseLonLat($lon, "[eE]", "[wW]");
           $latitude = ParseLonLat($lat, "[nN]", "[sS]");
       }

       if (!defined($longitudeEast) || !defined($latitude)) {
           $zip = $query->param('zip');
           if (defined($zip) && $zip ne "") {
               GetLonLatByZip($zip);
           }
       }

       $num = $query->param('num');
       if (defined($num) && $num ne "") {
           $numerals = $num;
       }

       $officialWidth = $query->param('width');
       if (!officialWidth) {
           $invalid = "Invalid width.";
       }
       $unit = $query->param('unit');
       if (!defined($unit) || ($unit ne "cm" and $unit ne "mm" and $unit ne "in" and $unit ne "ft")) {
           $invalid = "Invalid width unit.";
       }

       $location = $query->param('loc');

       $dstMode = $query->param('dst');

       $xy = $query->param('xy');

       $ins = $query->param('instructions');
       $instructions = defined($ins) && $ins;

       if ($dstMode eq "summer") {
           $tz++;
       }

       if (!defined($invalid) && (!defined($longitudeEast) || !defined($latitude))) {
           $invalid = "Missing latitude and/or longitude.";
       }
   }
}

$DEG2RAD = pi/180.;

@months = ( "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" );
@decs = ( -23.13, -17.3, -8,    4.25,   15,      22,  23.00, 18,    8.50,  -2.9, -14, -21.7, -23.13 );
@monthLen = (31, 28.25,  31,    30,     31,      30,   31,   31,    30,    31,     30,    31 );
@romanIV = ("", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII");
@romanIIII = ("", "I", "II", "III", "IIII", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII");

$pageWidth = 11 * 72;
$pageHeight = 8.5 * 72;
$margin = 1 * 72;
$inch = 72;
$arrowSize = 0.05*$inch;
$hourSize = 24;
$infoSize = 8;
$normInfoSize = 12;
$headSize = 24;
$lineWidth = 0.35;
$eotSize = 8;


$cosLatitude = cos($latitude * $DEG2RAD);
$sinLatitude = sin($latitude * $DEG2RAD);

$pdf = new PDF::Create('filename' => '-',
			      'Version'  => 1.2,
			      'Author'   => 'Alex Pruss',
			      'Title'    => 'Sun Dial for Latitude '.$latitude,
			 );

$root = $pdf->new_page('MediaBox'  => [ 0, 0, $pageWidth, $pageHeight ]);

$root->set_width($lineWidth);

$cx = $pageWidth / 2;
$cy = $pageHeight / 2;

$width = $pageWidth - 2 * $margin;
$height = $pageHeight - 2 * $margin;

$infoFont = $f = $pdf->font('Subtype'  => 'Type1',
   		        'Encoding' => 'WinAnsiEncoding',
   		        'BaseFont' => 'Helvetica');
$hourFont = $f = $pdf->font('Subtype'  => 'Type1',
   		        'Encoding' => 'WinAnsiEncoding',
   		        'BaseFont' => 'Helvetica-Bold');
$headFont = $hourFont;
$infoFontBold = $hourFont;

if (!defined($invalid) && (abs($latitude)<5 || abs($latitude)>89.9)) {
    $invalid = "Latitude must be between 5 and 89.9 degrees (north or south).";
}

if (defined($invalid)) {
    $page = $root->new_page;

    Heading("Invalid parameters.", $invalid);
    $pdf->close();
    exit;
}

if ($height < $width * abs($sinLatitude))  {
    $width = $height / abs($sinLatitude);
}
else {
    $height = $width * abs($sinLatitude);
}

$smajor = $width / 2;
$sminor = $height / 2;

# tzShift measures how much later tz-time is than local mean solar time
$tzShift = $tz * 15 - $longitudeEast;

if (180 <= $tzShift) {
    $tzShift -= 360;
}
if ($tzShift < -180) {
    $tzShift += $180;
}


if ($instructions) {
    $page = $root->new_page;
    
    Axes();
    CompassRose($margin, $margin, $margin);
    Measurement($cx,$cy+$sminor,$cx,$cy);
    Measurement($cx,$cy,$cx,$cy-$sminor);
    Measurement($cx-$smajor,$cy,$cx,$cy);
    Measurement($cx,$cy,$cx+$smajor,$cy);
    Location();
    
    Heading("Step 2: Draw the axes","Make sure to align the N arrow to true north (not magnetic)");
    
    $page = $root->new_page;
    
    Axes();
    CompassRose($margin, $margin, $margin);
    DrawEllipse($cx, $cy, $smajor, $sminor);
    $focus = sqrt($smajor*$smajor - $sminor*$sminor);
    DrawFocus($cx-$focus, $cy);
    DrawFocus($cx+$focus, $cy);
    Measurement($cx, $cy, $cx+$focus, $cy, 0);
    Measurement($cx-$focus, $cy, $cx, $cy, 0);
    Heading("Step 3: Draw the ellipse",
       "Use a loop of length ".Length(2*($focus+$smajor))." to draw ellipse.");

    if ($xy) {
        $page = $root->new_page;

        Axes();
        CompassRose($margin, $margin, $margin);
        DrawEllipse($cx, $cy, $smajor, $sminor);

        MarkHours($xy);

        Heading("Step 4a: Draw the hour labels");
    }

    $page = $root->new_page;

    Axes();
    CompassRose($margin, $margin, $margin);
    DrawEllipse($cx, $cy, $smajor, $sminor);

    MarkHours(0);

    for $i (4..21) {
        MeasureHour($i,0);
    }
    for $i (4..21) {
        MeasureHour($i,1);
    }

    if ($xy) {
        Heading("Step 4b: Verify hour label distances");
    }
    else {
        Heading("Step 4: Draw hour labels");
    }

    $page = $root->new_page;

    Axes();
    CompassRose($margin, $margin, $margin);
    DrawEllipse($cx, $cy, $smajor, $sminor);
    MarkHours(0);

    for $i (0..5) {
        GnomonTick($i, 0, 1);
    }
    GnomonTick(6, 0, 0);
    for $i (6..11) {
        GnomonTick($i, 1, 1);
    }
    GnomonTick(0, 1, 0);

    Heading("Step 5: Draw monthly gnomon position tickmarks",
       "Put the tickmarks at the indicated distances from the horizontal line.");
}
$page = $root->new_page;

CompassRose($margin, $margin, $margin);
DrawEllipse($cx, $cy, $smajor, $sminor);
MarkHours(0);

for $i (0..5) {
    GnomonBox($cx, $cx+0.4*$inch, $i);
}
for $i (6..11) {
    GnomonBox($cx-0.4*$inch, $cx, $i);
}

Location();
EquationOfTime($pageWidth-$margin, $pageHeight-$margin/3);

if ($dstMode eq "summer") {
    $dstMsg = "Subtract one hour for winter time";
}
elsif ($dstMode eq "winter") {
    $dstMsg = "Add one hour for summer time";
}
else {
    $dstMsg = "";
}
Heading(!$instructions ? "Analemmatic Sundial" : "Step 6: Indicate monthly gnomon positions",
$dstMsg);


$pdf->close;

# Round some coordinates to decrease pdf bandwidth
sub Round {
  my $x = shift;
  return int($x*100+.5)/100;
}

sub DrawEllipse {
  my $cx = shift;
  my $cy = shift;
  my $a = shift;
  my $b = shift;

  $page->newpath;

  for (my $i=0; $i<360; $i+=5) {
      my $x = $cx + $a * cos($i * $DEG2RAD);
      my $y = $cy + $b * sin($i * $DEG2RAD);
      if ($i == 0) {
          $page->moveto(Round($x), Round($y));
      }
      else {
          $page->lineto(Round($x), Round($y));
      }
  }

  $page->closepath;
  $page->stroke;
}

sub GnomonTick {
     my $i = shift;
     my $left = shift;
     my $arrow = shift;

     my $sign = ($latitude>=0)?1:-1;

     my $y = $cy+$sign*tan($DEG2RAD*$decs[$i])*$cosLatitude*$smajor;

     my $w = 0.1*$inch;

     if ($left) {
         Line($cx-$w, $y, $cx, $y);
         if ($arrow) {
             InfoColor();
             Line($cx-$w*4, $y, $cx-$w-4, $y);
             $page->stringr($infoFont, $infoSize, Round($cx-$w*4-4), Round($y-$infoSize/2),
                 Length(abs($y-$cy)));
             Line($cx-$w-4-$w/4, $y+$w/4, $cx-$w-4, $y);
             Line($cx-$w-4-$w/4, $y-$w/4, $cx-$w-4, $y);
             NormalColor();
         }
     }
     else {
         Line($cx+$w, $y, $cx, $y);
         if ($arrow) {
             InfoColor();
             Line($cx+$w*4, $y, $cx+$w+4, $y);
             $page->stringl($infoFont, $infoSize, Round($cx+$w*4+4), Round($y-$infoSize/2),
                 Length(abs($y-$cy)));
             Line($cx+$w+4+$w/4, $y+$w/4, $cx+$w+4, $y);
             Line($cx+$w+4+$w/4, $y-$w/4, $cx+$w+4, $y);
             NormalColor();
         }
     }
}

sub GnomonBox {
     my $x1 = shift;
     my $x2 = shift;
     my $i = shift;
     my $measure = shift;

     my $sign = ($latitude>=0)?1:-1;

     my $y1 = $cy+$sign*tan($DEG2RAD*$decs[$i])*$cosLatitude*$smajor;
     my $y2 = $cy+$sign*tan($DEG2RAD*$decs[$i+1])*$cosLatitude*$smajor;

     $left = ($x1+$x2)/2 < $cx;

     Line($x1,$y1,$x2,$y1);
     Line($x1,$y2,$x2,$y2);
     Line($cx, $y1, $cx, $y2);

     my $y = Round(($y1<$y2) ? $y1 : $y2);
     my $h = abs($y2-$y1);

     if ($h<10) {
        my $w = abs($x2-$x1)/4;
        if($left) {
            my $r = $x1 - 2;
            Line($r-$w, $y+$h/2, $r, $y+$h/2);
            Line($r-$w/4, $y+$h/2+$w/4, $r, $y+$h/2);
            Line($r-$w/4, $y+$h/2-$w/4, $r, $y+$h/2);
            $page->stringr($infoFont, 12, Round($r-$w-3), Round($y+$h/2-5.5), $months[$i]);
        }
        else {
            my $l = $x2 + 2;
            Line($l, $y+$h/2, $l+$w, $y+$h/2);
            Line($l, $y+$h/2, $l+$w/4, $y+$h/2+$w/4);
            Line($l, $y+$h/2, $l+$w/4, $y+$h/2-$w/4);
            $page->stringl($infoFont, 12, Round($l+$w+3), Round($y+$h/2-5.5), $months[$i]);
        }
     }
     else {
        if ($left) {
            $page->stringr($infoFont, 12, $cx-6, Round($y+.5*abs($y2-$y1)-5.5), $months[$i]);
        }
        else {
            $page->stringl($infoFont, 12, $cx+6, Round($y+.5*abs($y2-$y1)-5.5), $months[$i]);
        }
        if ($measure) {
            if (($x1+$x2)/2>$cx) {
                Measurement($x2, $y, $x2, $y+$h);
            }
            else {
                Measurement($x1, $y+$h, $x1, $y);
            }
        }
     }
}

sub DrawFocus {
     my $x = shift;
     my $y = shift;

     InfoColor();
#     $page->line($x-0.1*$inch, $y-0.1*$inch, $x+0.1*$inch, $y+0.1*$inch);
#     $page->line($x-0.1*$inch, $y+0.1*$inch, $x+0.1*$inch, $y-0.1*$inch);
     DrawEllipse($x,$y,0.05*$inch,0.05*$inch);
     NormalColor();
}

sub Fraction8 {
    my $x = shift;
    
    if ($x == 0) {
        return "0";
    }
    elsif ($x == 4) {
        return "1/2";
    }
    elsif ($x == 2) {
        return "1/4";
    }
    elsif ($x == 6) {
        return "3/4";
    }
    else {
        return $x."/8";
    }
}

sub Length {
     my $x = shift;

     $x = $x * $officialWidth / (2 * $smajor);

     if ($unit eq "cm" || $unit eq "mm") {
         if ($officialWidth >= 400) {
             return int($x+.5).$unit;
         }
         else {
             return sprintf "%.1f%s", $x, $unit;
         }
     }

     my $adjOfficialWidth;

     my $sign = ($x < 0);
     $x = abs($x);

     # feet or inches
     if ($unit eq "ft") {
         $x *= 12;
         $adjOfficialWidth = $officialWidth * 12;
     }
     else {
         $adjOfficialWidth = $officialWidth;
     }

     if ($adjOfficialWidth >= 400) {
         $x = 8 * int($x + .5);
     }
     else {
         $x = int($x * 8 + .5);
     }

     my $s;

     if ($unit eq "ft") {
        $s = int($x / (12*8)) . "'";
        $x %= 12*8;
     }
     else {
        $s = "";
     }

     $s .= int($x / 8);

     if ($x % 8 != 0) {
        $s .= " ".Fraction8($x % 8)."\"";
        if ($sign) {
            $s = "-($s)";
        }
     }
     else {
        $s = $s."\"";
        if ($sign) {
            $s = "-$s";
        }
     }
     
     return $s;
}

sub Measurement {
     my $x1 = shift;
     my $y1 = shift;
     my $x2 = shift;
     my $y2 = shift;
     my $labelOnly = shift;

     InfoColor();

     $dx0 = $x2-$x1;
     $dy0 = $y2-$y1;

     my $length = sqrt($dx0*$dx0+$dy0*$dy0);
     my $dx = $dx0 / $length;
     my $dy = $dy0 / $length;

     $dx *= $arrowSize;
     $dy *= $arrowSize;

     my $nx = -$dy;
     my $ny = $dx;

     $x1 -= 1.1 * $nx;
     $y1 -= 1.1 * $ny;
     $x2 -= 1.1 * $nx;
     $y2 -= 1.1 * $ny;

     $page->set_width($lineWidth/2);
     if (!$labelOnly) {
       Line($x1, $y1, $x2, $y2);

       Line($x1 + $nx, $y1 + $ny, $x1-$nx, $y1 - $ny);
       Line($x1, $y1, $x1+$dx+.8*$nx, $y1+$dy+.8*$ny);
       Line($x1, $y1, $x1+$dx-.8*$nx, $y1+$dy-.8*$ny);

       Line($x2+$nx, $y2 + $ny, $x2-$nx, $y2 - $ny);
       Line($x2, $y2, $x2-$dx+.8*$nx, $y2-$dy+.8*$ny);
       Line($x2, $y2, $x2-$dx-.8*$nx, $y2-$dy-.8*$ny);
     }
     InfoText(($x1+$x2)/2, ($y1+$y2)/2, Length($length));
     $page->set_width($lineWidth);

     NormalColor();
}

sub Line {
     my $a = Round(shift);
     my $b = Round(shift);
     my $c = Round(shift);
     my $d = Round(shift);
     $page->line($a,$b,$c,$d);
}

sub InfoText {
     my $x = shift;
     my $y = shift;
     my $text = shift;

     my $w = $page->string_width($infoFont, $text)*$infoSize;

     $page->setrgbcolor(1, 1, 1);
     $page->setrgbcolorstroke(1, 1, 1);
     FilledRectangle($x-$w/2,$y-1.2*$infoSize/2,$x+$w/2,$y+1.2*$infoSize/2);
     InfoColor();

     Stringc($infoFont, $infoSize, $x, $y-$infoSize/2, $text);
     NormalColor();
}

sub FilledRectangle {
     my $x0 = Round(shift);
     my $y0 = Round(shift);
     my $x1 = Round(shift);
     my $y1 = Round(shift);

     $page->newpath;
     $page->moveto($x0,$y0);
     $page->lineto($x0,$y1);
     $page->lineto($x1,$y1);
     $page->lineto($x1,$y0);
     $page->closepath;
     $page->fill;
}

sub UnfilledRectangle {
     my $x0 = Round(shift);
     my $y0 = Round(shift);
     my $x1 = Round(shift);
     my $y1 = Round(shift);

     $page->newpath;
     $page->moveto($x0,$y0);
     $page->lineto($x0,$y1);
     $page->lineto($x1,$y1);
     $page->lineto($x1,$y0);
     $page->closepath;
     $page->stroke;
}


sub InfoColor {
     $page->setrgbcolor(0, 0, .5);
     $page->setrgbcolorstroke(0, 0, .5);
}

sub NormalColor {
     $page->setrgbcolor(0, 0, 0);
     $page->setrgbcolorstroke(0, 0, 0);
}

sub Axes {
    $page->setrgbcolor(0, 0.5, 0);
    $page->setrgbcolorstroke(0, 0.5, 0);
    Line($cx-$smajor, $cy, $cx+$smajor, $cy);
    Line($cx, $cy-$sminor, $cx, $cy+$sminor);
    NormalColor();
}

sub Step {
    my $s;

    return ($step eq "all") || ($step =~ /$s/);
}

# midnight = 0, 6 am = 90, noon = 180, 6 pm = 270
sub HourAngle {
    my $h = shift;

    return ($h *(360.0/24.0)) - $tzShift;
}

sub HourXY {
    my $h = shift;

    my $angle = HourAngle($h);

    return (-sin($angle*$DEG2RAD), -cos($angle*$DEG2RAD));
}

sub GetHourLabel {
    my $h = shift;

    if (12 < $h) {
        $h = $h - 12;
    }
    elsif ($h == 0) {
        $h = 12;
    }

    if ($numerals eq "roman") {
        $h = $romanIV[$h];
    }
    elsif ($numerals eq "romaniiii") {
        $h = $romanIIII[$h];
    }
    
    return $h;
}

sub Dist {
     my $x0 = shift;
     my $y0 = shift;
     my $x1 = shift;
     my $y1 = shift;

     my $dx = $x0-$x1;
     my $dy = $y0-$y1;

     return sqrt($dx*$dx+$dy*$dy);
}

sub MarkHour {
    my $h = shift;
    my $showXY = shift;

    my ($rx, $ry) = HourXY($h);

    if ($latitude < 0) {
        $rx = -$rx;
    }

    my $x = $cx + $smajor * $rx;
    my $y = $cy + $sminor * $ry;

    my $dx = $rx * $smajor;
    my $dy = $ry * $sminor;
    my $length = sqrt($dx*$dx + $dy*$dy);

    $dx /= $length;
    $dy /= $length;

    if ($h == int($h)) {
        $lenIn = .1;
        $lenOut = .1;
    }
    else {
        $lenIn = 0;
        $lenOut = 0.05;
    }

    Line($x-$dx*$lenIn*$inch, $y-$dy*$lenIn*$inch, $x+$dx*$lenOut*$inch, $y+$dy*$lenOut*$inch);

    if ($h == int($h)) {
        Stringc($hourFont, $hourSize, $x + $dx * $hourSize, $y + $dy * $hourSize - $hourSize /2, GetHourLabel($h));
        if ($showXY) {
            InfoText($x + $dx * $hourSize, $y + $dy * $hourSize - $hourSize /2 - $infoSize,
               "(".Length($x-$cx).",".Length($y-$cy).")");
        }
    }
}

sub MeasureHour {
    my $h = shift;
    my $labelOnly = shift;

    my $closestTheta = undef;
    my $closestD = undef;
    my ($x, $y) = HourXY($h);

    $x *= $smajor;
    $y *= $sminor;

    for (my $theta = 0; $theta < 360 ; $theta += 90) {
         my $d = Dist($x, $y, -$smajor*sin($theta * $DEG2RAD), -$sminor*cos($theta * $DEG2RAD));
         if (!defined($closestD) || $d < $closestD) {
              $closestD = $d;
              $closestTheta = $theta;
         }
    }

    my $theta = $closestTheta;
    my $hourAngle = HourAngle($h);

    my $delta = $theta - $hourAngle;
    if ($delta < -180) {
        $delta += 360;
    }
    elsif (180 <= $delta) {
        $delta -= 360;
    }

    if (0<$delta) {
        Measurement($cx + $x, $cy + $y, $cx - $smajor*sin($theta *$DEG2RAD), $cy - $sminor*cos($theta * $DEG2RAD), $labelOnly);
    }
    else {
        Measurement($cx - $smajor*sin($theta *$DEG2RAD), $cy - $sminor*cos($theta * $DEG2RAD), $cx + $x, $cy + $y, $labelOnly);
    }
}

sub Heading {
    my $text = shift;
    my $subhead = shift;

    $page->stringl($headFont, $headSize, $margin, $pageHeight-$margin/2, $text);
    if (defined($subhead) && $subhead ne "") {
        $page->stringl($infoFont, $normInfoSize, $margin, $pageHeight-$margin/2-$headSize, $subhead);
    }
}

sub Shape {
    my $shape = shift;
    my $x = shift;
    my $y = shift;
    my $size = shift;

    $page->newpath;

    my $a = $x + $size*(${$shape}[0]);
    my $b = $y + $size*(${$shape}[1]);

    $page->moveto($a, $b);

    for my $i (0..(@$shape-1)/2) {
        $page->lineto(Round($x+$size*($shape->[2*$i])), Round($y+$size*($shape->[2*$i+1])));
    }
    $page->fill;
}


sub CompassRose {
    my $x = shift;
    my $y = shift;
    my $size = shift;

    my @upArrow = (
         .333, 0,
         .5, .33,
         .667, 0,
         .5, 1 );

    my @downArrow = (
         .333, 1-0,
         .5, 1-.33,
         .667, 1-0,
         .5, 1-1 );

    $page->setrgbcolor(1, 0, 0);
    $page->setrgbcolorstroke(1, 0, 0);
    if ($latitude>=0) {
       Shape(\@upArrow, $x, $y, $size);
       Stringc($hourFont, $hourSize, $x+.5*$size, $y+$size, "N");
    }
    else {
       Shape(\@downArrow, $x, $y, $size);
       Stringc($hourFont, $hourSize, $x+.5*$size, $y-$hourSize, "N");
    }
    NormalColor();
}

sub Stringc {
    my $font = shift;
    my $size = shift;
    my $x = shift;
    my $y = shift;
    my $text = shift;

    $page->stringc($font, Round($size), Round($x), Round($y), $text);
}

sub Location {
    my $latLabel = $latitude > 0 ? $latitude."N" : (-$latitude)."S";
    my $lonLabel = $longitudeEast > 0 ? $longitudeEast."E" : (-$longitudeEast)."W";
    my $tzLabel = $tz > 0 ? "+".$tz : $tz;
    $page->stringr($infoFont, $infoSize, $pageWidth-$margin, $margin,
        "$location (Lat.: $latLabel, Lon.: $lonLabel, TZ: UTC$tzLabel)");
}

sub EOTText {
    my $N = shift;
    my $B = 360. * ($N-81) / 365;


    my $cor = -( 9.87 * sin(2 * $B * $DEG2RAD) - 7.67 * sin(($B + 78.7) * $DEG2RAD));

    $cor = int($cor + 0.5);
    if ($cor<=0) {
        return $cor;
    }
    else {
        return "+".$cor;
    }
}

sub EquationOfTime {
    my $x = shift;
    my $y = shift;

    my $day = 1;
    $page->string($infoFontBold, $eotSize, $x, $y, "Correction");
    $y -= $eotSize;
    $page->string($infoFontBold, $eotSize, $x, $y, "(min.):");
    $y -= $eotSize;

    for my $i (0..11) {
        $page->string($infoFont, $eotSize, $x, $y, $months[$i]." 1: ".
           EOTText($day));
        $y -= $eotSize;
        $page->string($infoFont, $eotSize, $x, $y, $months[$i]." 15: ".
           EOTText($day+14));
        $y -= $eotSize;
        $day += $monthLen[$i];
    }
}

sub MarkHours {
    my $showXY = shift;
    for $i (4..21) {
        MarkHour($i, $showXY);
        MarkHour($i+.25, $showXY);
        MarkHour($i+.5, $showXY);
        MarkHour($i+.75, $showXY);
    }
}

sub ParseLonLat {
    my $x = shift;
    my $posRE = shift;
    my $negRE = shift;
    
    my $sign = 1;
    
    $x =~ s/^\s+//;
    $x =~ s/\s+$//;

    if ($x =~ /^-(.*)/) {
       $sign = -$sign;
       $x = $1;
    }
    elsif ($x =~ /^\+(.*)/) {
       $x = $1;
    }

    if ($x =~ /(.*)\s*$posRE$/) {
       $x = $1;
    }
    elsif ($x =~ /(.*)\s*$negRE$/) {
       $x = $1;
       $sign = -$sign;
    }

    if ($x =~ /^([0-9]+)\s+([0-9]+)\s+([0-9.]+)/) {
        $x = $1 + ($2 + $3/60.)/60.;
    }
    elsif ($x =~ /^([0-9]+)\s+([0-9]+)/) {
        $x = $1 + $2/60.;
    }
    elsif (! ($x =~ /^([0-9.]+)/)) {
        $invalid = "Invalid format for latitude or longitude.";
        return undef;
    }
    else {
        return $sign*$x;
    }
}


sub Usage {
   print STDERR "Usage:\nperl sundial.pl [zip=xxxxx | lat=[-]x.x[n|s] lon=[-]x.x[e|w]] tz=[-]h.h size=x.x[ft|in|cm|mm] [instructions=0] [dst=summer|winter|none] [loc=name] [xy=1] [num=arabic|roman|romaniiii]";
   exit 1;
}


sub ParseSize {
    my $s = shift;
    
    $s =~ s/^\s+//;
    $s =~ s/\s+$//;

    if ($s =~ /([0-9.]+)\s*(in|cm|ft|mm)/) {
        $officialWidth = $1;
        $unit = $2;
        return 1;
    }
    elsif ($s =~ /^([0-9.]+)$/ ) {
        $officialWidth = $1;
        $unit = "in";
        return 1;
    }
    else {
        $invalid = "Invalid size.";
        return 0;
    }
}

sub ExtractTZ {
    my $t = shift;

    if ($t =~ /\(UTC\)/) {
        return 0;
    }

    $t =~ s/^.*\(UTC\+?//;
    $t =~ s/:30/.5/;
    $t =~ s/:15/.25/;
    $t =~ s/:45/.75/;
    $t =~ s/\)//;
    $t =~ s/^-0/-/;
    $t =~ s/^0//;

    return $t;
}


sub ParseTZ {
    my $t = shift;

    $t =~ s/^\s+//;
    $t =~ s/\s+$//;
    $t =~ s/:30/.5/;
    $t =~ s/:15/.25/;
    $t =~ s/:45/.75/;
    if ($t =~ /(-[0-9]+\.?[0-9]*)/) {
        $tz = $1;
        return 1;
    }
    elsif ($t =~ /\+?([0-9]+\.?[0-9]*)/) {
        $tz = $1;
        return 1;
    }

    $tz = $TZ{uc($t)};
    if (!defined($tz)) {
        $invalid = "Invalid timezone.";
    }
    $tz = ExtractTZ($tz);
    return 1;

}



sub LoadTZNames {
    %TZ=(
        'ACDT'=>'Australian Central Daylight Time (UTC+10:30)',
        'ACST'=>'Australian Central Standard Time (UTC+09:30)',
        'ACT'=>'ASEAN Common Time (UTC+08)',
        'ADT'=>'Atlantic Daylight Time (UTC-03)',
        'AEDT'=>'Australian Eastern Daylight Time (UTC+11)',
        'AEST'=>'Australian Eastern Standard Time (UTC+10)',
        'AFT'=>'Afghanistan Time (UTC+04:30)',
        'AKDT'=>'Alaska Daylight Time (UTC-08)',
        'AKST'=>'Alaska Standard Time (UTC-09)',
        'AMST'=>'Armenia Summer Time (UTC+05)',
        'AMT'=>'Armenia Time (UTC+04)',
        'ART'=>'Argentina Time (UTC-03)',
        'ARAB'=>'Arab(ic) Standard Time (Kuwait, Riyadh, Baghdad) (UTC+03)',
        'ARABIAN'=>'Arabian Standard Time (Abu Dhabi, Muscat) (UTC+04)',
        'AST'=>'Atlantic Standard Time (UTC-04)',
        'AWDT'=>'Australian Western Daylight Time (UTC+09)',
        'AWST'=>'Australian Western Standard Time (UTC+08)',
        'AZOST'=>'Azores Standard Time (UTC-01)',
        'AZT'=>'Azerbaijan Time (UTC+04)',
        'BDT'=>'Brunei Time (UTC+08)',
        'BIOT'=>'British Indian Ocean Time (UTC+06)',
        'BIT'=>'Baker Island Time (UTC-12)',
        'BOT'=>'Bolivia Time (UTC-04)',
        'BRT'=>'Brasilia Time (UTC-03)',
        'BANGLADESH'=>'Bangladesh Standard Time (UTC+06)',
        'BTT'=>'Bhutan Time (UTC+06)',
        'CAT'=>'Central Africa Time (UTC+02)',
        'CCT'=>'Cocos Islands Time (UTC+06:30)',
        'CDT'=>'Central Daylight Time (North America) (UTC-05)',
        'CEDT'=>'Central European Daylight Time (UTC+02)',
        'CEST'=>'Central European Summer Time (UTC+02)',
        'CET'=>'Central European Time (UTC+01)',
        'CHADT'=>'Chatham Daylight Time (UTC+13:45)',
        'CHAST'=>'Chatham Standard Time (UTC+12:45)',
        'CIST'=>'Clipperton Island Standard Time (UTC-08)',
        'CKT'=>'Cook Island Time (UTC-10)',
        'CLST'=>'Chile Summer Time (UTC-03)',
        'CLT'=>'Chile Standard Time (UTC-04)',
        'COST'=>'Colombia Summer Time (UTC-04)',
        'COT'=>'Colombia Time (UTC-05)',
        'CST'=>'Central Standard Time (North America) (UTC-06)',
        'CENTRALAUSTRALIA'=>'Central Standard Time (Australia) (UTC+09:30)',
        'CT'=>'China Time (UTC+08)',
        'CVT'=>'Cape Verde Time (UTC-01)',
        'CXT'=>'Christmas Island Time (UTC+07)',
        'CHST'=>'Chamorro Standard Time (UTC+10)',
        'DFT'=>'AIX specific equivalent of Central European Time (UTC+01)',
        'EAST'=>'Easter Island Standard Time (UTC-06)',
        'EAT'=>'East Africa Time (UTC+03)',
        'ECT'=>'Eastern Caribbean Time (does not recognise DST) (UTC-04)',
        'ECUADOR'=>'Ecuador Time (UTC-05)',
        'EDT'=>'Eastern Daylight Time (North America) (UTC-04)',
        'EEDT'=>'Eastern European Daylight Time (UTC+03)',
        'EEST'=>'Eastern European Summer Time (UTC+03)',
        'EET'=>'Eastern European Time (UTC+02)',
        'EST'=>'Eastern Standard Time (North America) (UTC-05)',
        'FJT'=>'Fiji Time (UTC+12)',
        'FKST'=>'Falkland Islands Summer Time (UTC-03)',
        'FKT'=>'Falkland Islands Time (UTC-04)',
        'GALT'=>'Galapagos Time (UTC-06)',
        'GET'=>'Georgia Standard Time (UTC+04)',
        'GFT'=>'French Guiana Time (UTC-03)',
        'GILT'=>'Gilbert Island Time (UTC+12)',
        'GIT'=>'Gambier Island Time (UTC-09)',
        'GMT'=>'Greenwich Mean Time (UTC)',
        'GST'=>'South Georgia and the South Sandwich Islands (UTC-02)',
        'GULF'=>'Gulf Standard Time (UTC+04)',
        'GYT'=>'Guyana Time (UTC-04)',
        'HADT'=>'Hawaii-Aleutian Daylight Time (UTC-09)',
        'HAST'=>'Hawaii-Aleutian Standard Time (UTC-10)',
        'HKT'=>'Hong Kong Time (UTC+08)',
        'HMT'=>'Heard and McDonald Islands Time (UTC+05)',
        'HST'=>'Hawaii Standard Time (UTC-10)',
        'ICT'=>'Indochina Time (UTC+07)',
        'IDT'=>'Israeli Daylight Time (UTC+03)',
        'IRKT'=>'Irkutsk Time (UTC+08)',
        'IRST'=>'Iran Standard Time (UTC+03:30)',
        'IST'=>'Indian Standard Time (UTC+05:30)',
        'IRELANDSUMMER'=>'Irish Summer Time (UTC+01)',
        'ISRAEL'=>'Israel Standard Time (UTC+02)',
        'JST'=>'Japan Standard Time (UTC+09)',
        'KRAT'=>'Krasnoyarsk Time (UTC+07)',
        'KST'=>'Korea Standard Time (UTC+09)',
        'LHST'=>'Lord Howe Standard Time (UTC+10:30)',
        'LINT'=>'Line Islands Time (UTC+14)',
        'MAGT'=>'Magadan Time (UTC+11)',
        'MDT'=>'Mountain Daylight Time (North America) (UTC-06)',
        'MIT'=>'Marquesas Islands Time (UTC-09:30)',
        'MSD'=>'Moscow Summer Time (UTC+04)',
        'MSK'=>'Moscow Standard Time (UTC+03)',
        'MALAYSIA'=>'Malaysian Standard Time (UTC+08)',
        'MST'=>'Mountain Standard Time (North America) (UTC-07)',
        'MYANMAR'=>'Myanmar Standard Time (UTC+06:30)',
        'MUT'=>'Mauritius Time (UTC+04)',
        'MYT'=>'Malaysia Time (UTC+08)',
        'NDT'=>'Newfoundland Daylight Time (UTC-02:30)',
        'NFT'=>'Norfolk Time[1] (UTC+11:30)',
        'NPT'=>'Nepal Time (UTC+05:45)',
        'NST'=>'Newfoundland Standard Time (UTC-03:30)',
        'NT'=>'Newfoundland Time (UTC-03:30)',
        'NZDT'=>'New Zealand Daylight Time (UTC+13)',
        'NZST'=>'New Zealand Standard Time (UTC+12)',
        'OMST'=>'Omsk Time (UTC+06)',
        'PDT'=>'Pacific Daylight Time (North America) (UTC-07)',
        'PETT'=>'Kamchatka Time (UTC+12)',
        'PHOT'=>'Phoenix Island Time (UTC+13)',
        'PKT'=>'Pakistan Standard Time (UTC+05)',
        'PST'=>'Pacific Standard Time (North America) (UTC-08)',
        'PHILIPPINE'=>'Philippine Standard Time (UTC+08)',
        'RET'=>'Réunion Time (UTC+04)',
        'SAMT'=>'Samara Time (UTC+04)',
        'SAST'=>'South African Standard Time (UTC+02)',
        'SBT'=>'Solomon Islands Time (UTC+11)',
        'SCT'=>'Seychelles Time (UTC+04)',
        'SGT'=>'Singapore Time (UTC+08)',
        'SLT'=>'Sri Lanka Time (UTC+05:30)',
        'SAMOA'=>'Samoa Standard Time (UTC-11)',
        'SST'=>'Singapore Standard Time (UTC+08)',
        'TAHT'=>'Tahiti Time (UTC-10)',
        'THA'=>'Thailand Standard Time (UTC+07)',
        'UTC'=>'Coordinated Universal Time (UTC)',
        'UYST'=>'Uruguay Summer Time (UTC-02)',
        'UYT'=>'Uruguay Standard Time (UTC-03)',
        'VET'=>'Venezuelan Standard Time (UTC-04:30)',
        'VLAT'=>'Vladivostok Time (UTC+10)',
        'WAT'=>'West Africa Time (UTC+01)',
        'WEDT'=>'Western European Daylight Time (UTC+01)',
        'WEST'=>'Western European Summer Time (UTC+01)',
        'WET'=>'Western European Time (UTC)',
        'WST'=>'Western Standard Time (UTC+08)',
        'YAKT'=>'Yakutsk Time (UTC+09)',
        'YEKT'=>'Yekaterinburg Time (UTC+05)'
    );
}


sub MakeTZList {
    my %US = ('EST'=>1, 'CST'=>1, 'MST'=>1, 'PST'=>1, 'HST'=>1);

    print "<option value='EST'>".$TZ{'EST'}."</option>\n";
    print "<option value='CST'>".$TZ{'CST'}."</option>\n";
    print "<option value='MST'>".$TZ{'MST'}."</option>\n";
    print "<option value='PST'>".$TZ{'PST'}."</option>\n";
    print "<option value='HST'>".$TZ{'HST'}."</option>\n";

    @TZList = ();
    for my $k (keys %TZ) {
        if (!$US{$k}) {
            push @TZList, $k unless $TZ{$k} =~ /(Summer|Daylight)/;
        }
    }
    @TZList = sort {ExtractTZ($TZ{$a}) <=> ExtractTZ($TZ{$b})} @TZList;

    for my $k (@TZList) {
        print "<option value='$k'>".$TZ{$k}."</option>\n";
    }
}


sub GetLonLatByZip {
    my $zip = shift;

    $latitude = undef;
    $longitudeEast = undef;

    $zip =~ s/^\s+//;
    $zip =~ s/\s+$//;

    if (! ($zip =~ /([0-9]+)/)) {
        $invalid = "Invalid zip code.";
        return;
    }

    if (! open (ZIP, "zipcodes.dat")) {
        $invalid = "Cannot open zip code database.";
        return;
    }

    binmode(ZIP);

    if (! seek(ZIP, ($zip-600)*8, SEEK_SET)) {
        close(ZIP);
        $invalid = "Invalid zip code.";
        return;
    }

    my $data;
    my $n = read ZIP, $data, 8;
    close(ZIP);

    if ($n != 8) {
        $invalid = "Invalid zip code.";
        return;
    }

    my ($lon, $lat) = unpack("NN", $data);

    if ($lat == 0xFFFFFFFF || $lon == 0xFFFFFFFF) {
        $invalid = "Unknown zip code.";
        return;
    }
    
    $latitude = $lat / 1000000.;
    $longitudeEast = -$lon / 1000000.;
}
