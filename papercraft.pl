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
$numerals = "arabic";

%color = (  "thicklines" => "000000",
            "thinlines" => "000000",
            "eot" => "000000",
            "circles" => "000000",
            "dial" => "ffffff",
            "hoursback" => "ffffff",
            "hours" => "0000FF",
            "gnomon" => "ffffff",
            "compass" => "FF0000",
            "dst" => "000000" );

if (@ARGV>0) {
   $tz = -5;
   $longitudeEast = -(97+8/60.);
   $latitude = 31 + 33/60.;

   while(@ARGV) {
       $_ = shift @ARGV;

       if (/tz=(.*)$/) {
           Usage() if !ParseTZ($1);
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
       elsif (/color-([a-z]+)=(.*)$/) {
           Usage() if !VerifyColor($2);
           $color{$1} = $2;
       }
       elsif (/num=(roman|romaniiii|romaniv|arabic|now)$/) {
           $numerals = $1;
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
<title>Papercraft Sundial PDF Generator</title>
<body bgcolor='#C6DEFF'>
<h1>Papercraft Sundial PDF  Generator</h1>
<p>There is a detailed
<a href="http://www.instructables.com/id/15-minute-paper-craft-sundial/">Instructable</a> for how to use this sundial generator, with lots of photos.
This is for a horizontal or "garden" (not analemmatic) sundial.  For instructions on making a large 
analemmatic sundial, 
go <a href="http://www.instructables.com/id/Large-driveway-sidewalk-or-garden-sundial/">here</a>.</p>

<h2>Enter location parameters</h2>

<p>You must enter either a zip code or
latitude/longitude, and select your timezone and daylight savings option.  Required options are in bold.</p>
<form action="papercraft.pl">
<b>Zip code: <input type="text" name="zip" size=12/>
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
</select><br/><br/>
For the following color settings, use <a href="http://www.computerhope.com/htmcolor.htm">numerical HTML color codes</a>,
such as "000000" for black, "FFFFFF" for white, "2B60DE" for royal blue.<br>

Dial background: <input type="text" name="color-dial" value="$color{dial}" size=12/><br/>
Hour label background: <input type="text" name="color-hoursback" value="$color{hoursback}" size=12/><br/>
Hour text: <input type="text" name="color-hours" value="$color{hours}" size=12/><br/>
Circles: <input type="text" name="color-circles" value="$color{circles}" size=12/><br/>
Hour lines: <input type="text" name="color-thicklines" value="$color{thicklines}" size=12/><br/>
15-minute lines: <input type="text" name="color-thinlines" value="$color{thinlines}" size=12/><br/>
Gnomon: <input type="text" name="color-gnomon" value="$color{gnomon}" size=12/><br/>
North arrow: <input type="text" name="color-compass" value="$color{compass}" size=12/><br/>
Correction table text: <input type="text" name="color-eot" value="$color{eot}" size=12/><br/>
Daylight savings adjustment text: <input type="text" name="color-dst" value="$color{dst}" size=12/><br/>
<input type="submit" name="go" value="Go!"/>
</form>
<h2>Source code and references</h2>
<p>The source code for this perl script is available <a href="http://github.com/arpruss/sundials-etc">here</a>.  You need to get papercraft.pl and zipcodes.dat, and keep them in the same directory.  You will also need the
<a href="http://search.cpan.org/~markusb/PDF-Create-1.06/lib/PDF/Create.pm">PDF::Create</a> perl package.</p>
<p>I used a formula from
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

       $dstMode = $query->param('dst');

       if ($dstMode eq "summer") {
           $tz++;
       }

       foreach (keys %color) {
           $c = $query->param("color-$_");
           if (VerifyColor($c)) {
               $color{$_} = $c;
           }
       }

       if (!defined($invalid) && (!defined($longitudeEast) || !defined($latitude))) {
           $invalid = "Missing latitude and/or longitude.";
       }
   }
}

$DEG2RAD = pi/180.;

@months = ( "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" );
@monthLen = (31, 28.25,  31,    30,     31,      30,   31,   31,    30,    31,     30,    31 );
@romanIV = ("", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII");
@romanIIII = ("", "I", "II", "III", "IIII", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII");

$pageWidth = 11 * 72;
$pageHeight = 8.5 * 72;
$margin = .5 * 72;
$inch = 72;
$hourSize = 20;
$infoSize = 9;
$normInfoSize = 12;
$headSize = 24;
$lineWidth = 0.35;
$eotSize = 8;


$pdf = new PDF::Create('filename' => '-',
			      'Version'  => 1.2,
			      'Author'   => 'Alex Pruss',
			      'Title'    => 'Sun Dial for Latitude '.$latitude,
			 );

$root = $pdf->new_page('MediaBox'  => [ 0, 0, $pageWidth, $pageHeight ]);

$root->set_width($lineWidth);

$cx = $pageWidth / 2;
$cy = $pageHeight / 2;

$height = $pageHeight - 2 * $margin;

$infoFont = $f = $pdf->font('Subtype'  => 'Type1',
   		        'Encoding' => 'WinAnsiEncoding',
   		        'BaseFont' => 'Helvetica');
$hourFont = $f = $pdf->font('Subtype'  => 'Type1',
   		        'Encoding' => 'WinAnsiEncoding',
   		        'BaseFont' => 'Helvetica-Bold');
$headFont = $hourFont;
$infoFontBold = $hourFont;

$page = $root->new_page;

if (!defined($invalid) && (abs($latitude)<24 || abs($latitude)>60)) {
    $invalid = "Latitude must be between 24 and 60 degrees (north or south).";
}

if (defined($invalid)) {
    Heading("Invalid parameters.", $invalid);
    $pdf->close();
    exit;
}

$hourAreaWidth = $hourSize * 1.7;
$alpha = 0.5;
$r = ($height / 2 - $hourAreaWidth);
$delta = 23.4 * $DEG2RAD;
$psi = 60 * $DEG2RAD;
$theta = abs($latitude) * $DEG2RAD;
$phi = atan2(sin($alpha*$theta), cos($psi/2)*cos($alpha*$theta));
$a = $r * cos($theta+$delta) / cos($theta+$delta-$alpha*$theta);
$b = $a / cos($alpha*$theta);
$c = $b * sin($alpha*$theta);
$d = $c * tan($psi/2);
$e = $c / cos($psi/2);
$f = sqrt($a*$a + $e*$e);
$g = $r * cos($theta-$delta) / cos($delta);
$gamma = asin($d/$f);
$epsilon = (1-$alpha)*$theta;

# tzShift measures how much later tz-time is than local mean solar time
$tzShift = $tz * 15 - $longitudeEast;

if (180 <= $tzShift) {
    $tzShift -= 360;
}
if ($tzShift < -180) {
    $tzShift += $180;
}


DrawEllipse($cx,$cy,$r+$hourAreaWidth,$r+$hourAreaWidth,"circles", "hoursback");
DrawEllipse($cx,$cy,$r,$r,"circles", "dial");
MarkHours();
EquationOfTime($cx, $cy - 0.12*$r);

$page->setrgbcolor(255, 255, 255);
$page->newpath;
$page->moveto($cx,$cy);
$page->lineto($cx-($f/2)*sin($gamma),$cy+($f/2)*cos($gamma));
$page->lineto($cx,$cy+$f/2);
$page->lineto($cx+($f/2)*sin($gamma),$cy+($f/2)*cos($gamma));
$page->closepath;
$page->fill;

$page->set_width($lineWidth/2);
Line($cx,$cy,$cx,$cy+$f/2);
Line($cx,$cy,$cx-($f/2)*sin($gamma),$cy+($f/2)*cos($gamma));
Line($cx-($f/2)*sin($gamma),$cy+($f/2)*cos($gamma),$cx,$cy+$f/2);
Line($cx,$cy+$f/2,$cx+($f/2)*sin($gamma),$cy+($f/2)*cos($gamma));
Line($cx+($f/2)*sin($gamma),$cy+($f/2)*cos($gamma), $cx, $cy);
$page->set_width($lineWidth);
NormalColor();

CompassRose($cx-0.4*$r, $cy-0.8*$r, $inch*.6);
if ($dstMode eq "summer") {
    DST($cx+0.4*$r, $cy-0.8*$r+$hourSize, "Subtract one hour", "for winter time");
}
elsif ($dstMode eq "winter") {
    DST($cx+0.4*$r, $cy-0.8*$r+$hourSize, "Add one hour", "for summer time");
}

$page = $root->new_page;

$gy = $height-$g;

@gnomon=(
         0, $g,
         $a*sin($epsilon),$a*cos($epsilon),
        ($f/2)*sin($epsilon+$phi),($f/2)*cos($epsilon+$phi),
        ($f/2)*sin($epsilon+$phi+$gamma),($f/2)*cos($epsilon+$phi+$gamma));


SetColor("gnomon");
$page->set_width($lineWidth);

GnomonPath(1);
$page->fill;
GnomonPath(0);
$page->stroke;

($cr,$cg,$cb) = rgb("gnomon");
if ($cr+$cg+$cb>1.5) {
    $page->setrgbcolorstroke(0,0,0);
}
else {
    $page->setrgbcolorstroke(255,255,255);
}
Mountain($cx,$gy,$cx+$gnomon[0],$gy+$gnomon[1]);
Valley($cx,$gy,$cx+$gnomon[2],$gy+$gnomon[3]);
Valley($cx,$gy,$cx-$gnomon[2],$gy+$gnomon[3]);
NormalColor();
Mountain($cx,$gy,$cx+$gnomon[4],$gy+$gnomon[5]);
Mountain($cx,$gy,$cx-$gnomon[4],$gy+$gnomon[5]);

$page->set_width($lineWidth*.8);
Line($cx,$gy,$cx+$gnomon[6],$gy+$gnomon[7]);
Line($cx,$gy,$cx-$gnomon[6],$gy+$gnomon[7]);
$page->newpath;
$page->moveto($margin,$margin);
$page->lineto($margin,$margin+$g*sin($theta));
$page->lineto($margin+$g*cos($theta),$margin);
$page->closepath;
$page->stroke;
InfoText($margin+$g*cos($theta)/2, $margin+$infoSize, "Gnomon sizer");

$page->set_width($lineWidth);

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
  my $stroke = shift;
  my $fill = shift;

  SetColor($fill);

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
  $page->fill;

  SetColor($stroke);
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

#     $page->setrgbcolor(1, 1, 1);
#     $page->setrgbcolorstroke(1, 1, 1);
#     FilledRectangle($x-$w/2,$y-1.2*$infoSize/2,$x+$w/2,$y+1.2*$infoSize/2);
#     InfoColor();

     Stringc($infoFont, $infoSize, $x, $y-$infoSize/2, $text);
#     NormalColor();
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
     $page->setrgbcolor(0, 0, 0);
     $page->setrgbcolorstroke(0, 0, 0);
}

sub NormalColor {
     $page->setrgbcolor(0, 0, 0);
     $page->setrgbcolorstroke(0, 0, 0);
}

# midnight = 0, 6 am = 90, noon = 180, 6 pm = 270
sub HourAngle {
    my $h = shift;

    return ($h *(360.0/24.0)) - $tzShift;
}

sub HourXY {
    my $h = shift;

    # angle from vertical
    my $angle = (HourAngle($h)-180) * $DEG2RAD;
    my $x = sin($angle)*sin($theta);
    my $y = cos($angle);
    my $rad = sqrt($x*$x+$y*$y);
    return ($x/$rad, $y/$rad);
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
    elsif ($numerals eq "now") {
        $h = "now";
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

    my $x = $cx + $r * $rx;
    my $y = $cy + $r * $ry;

    my $length = $r; # sqrt($dx*$dx + $dy*$dy);

    if ($h == int($h)) {
        SetColorStroke("thicklines");
        $page->set_width($lineWidth*5.5);
    }
    else {
        SetColorStroke("thinlines");
        $page->set_width($lineWidth*.7);
    }

    Line($cx+$r*$rx*.1, $cy+$r*$ry*.1, $x, $y);

    $page->set_width($lineWidth);

    if ($h == int($h)) {
        SetColorStroke("hours");
        SetColor("hours");
        stringcrot($hourFont, $hourSize, $x + $rx * $hourSize/2, $y + $ry * $hourSize/2,
           atan2($ry,$rx)-pi()/2,
           GetHourLabel($h));
    }

    NormalColor();
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

    $x -= $size/2*.5;
    $y -= $size/2*.5;

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

    SetColor("compass");
    SetColorStroke("compass");
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
    
    SetColorStroke("eot");
    SetColor("eot");

    my $day = 1;
    $page->stringc($infoFontBold, $eotSize, $x, $y, "Correction");
    $y -= $eotSize;
    $page->stringc($infoFontBold, $eotSize, $x, $y, "(min.):");
    $y -= $eotSize;

    for my $i (0..11) {
        $page->stringc($infoFont, $eotSize, $x, $y, $months[$i]." 1: ".
           EOTText($day));
        $y -= $eotSize;
        $page->stringc($infoFont, $eotSize, $x, $y, $months[$i]." 15: ".
           EOTText($day+14));
        $y -= $eotSize;
        $day += $monthLen[$i];
    }
    
    NormalColor();
}

sub MarkHours {
    my $showXY = shift;
    for $i (6..20) {
        MarkHour($i, $showXY);
        MarkHour($i+.25, $showXY);
        MarkHour($i+.5, $showXY);
        MarkHour($i+.75, $showXY);
    }
    MarkHour(21, $showXY);
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
   print STDERR "Usage:\nperl papercraft.pl [zip=xxxxx | lat=[-]x.x[n|s] lon=[-]x.x[e|w]] ".
   "tz=[-]h.h [dst=summer|winter|none] [loc=name] [num=arabic|roman|romaniiii] ".
   "[color-thicklines|thinlines|eot|circles|dial|hoursback|hours|gnomon|compass|dst]=rrggbb";
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

sub Mountain {
    my $x1 = shift;
    my $y1 = shift;
    my $x2 = shift;
    my $y2 = shift;

    Pattern($x1,$y1,$x2,$y2,0.02*$inch,0.05*$inch,0.06*$inch,0.05*$inch);
}

sub Valley {
    my $x1 = shift;
    my $y1 = shift;
    my $x2 = shift;
    my $y2 = shift;

    Pattern($x1,$y1,$x2,$y2,0.06*$inch,0.05*$inch,0.06*$inch,0.05*$inch);
}

sub Pattern {
    my $x1 = shift;
    my $y1 = shift;
    my $x2 = shift;
    my $y2 = shift;

    my @lengths = (shift, shift, shift, shift);
    my @draw = (1,0,1,0);

    my $dx = $x2-$x1;
    my $dy = $y2-$y1;
    my $l = sqrt($dx*$dx+$dy*$dy);
    if ($l == 0) {
        return;
    }
    $dx /= $l;
    $dy /= $l;

    my $r = 0;
    my $i = 0;

    while($r < $l) {
       my $r1 = $r + $lengths[$i];
       if ($r1 > $l) {
           $r1 = $l;
       }
       Line($x1+$dx*$r,$y1+$dy*$r,$x1+$dx*$r1,$y1+$dy*$r1) if $draw[$i];
       $r += $lengths[$i];
       $i = ($i+1) % @lengths;
    }
}

#
# adapted from PDF::Create
# Copyright 1999-2001 Fabien Tassin
# Copyright 2007-     Markus Baertschi <markus@markus.org>
# Copyright 2010      Gary Lieberman
#
sub stringcrot
{
	my $font = shift;
	my $size = shift;
	my $x    = shift;
	my $y    = shift;
	my $angle = shift;
	my $s    = shift;

	$page->{'pdf'}->uses_font( $page, $font );
	my $w = $page->string_width($font, $s) * $size;
	$s =~ s/([\\\(\)])/\\$1/g;
	my $cos = cos($angle);
	my $sin = sin($angle);
	$x -= ($w/2) * $cos;
	$y -= ($w/2) * $sin;
	$page->{'pdf'}->add(sprintf " BT /F$font $size Tf %.5f %.5f %.5f %.5f %.5f %.5f Tm ($s) Tj ET", $cos, $sin, -$sin, $cos, $x, $y);
}

sub rgb
{
    my $cname = shift;
    my $c = $color{$cname};
    my $r = hex(substr($c,0,2))/255.;
    my $g = hex(substr($c,2,2))/255.;
    my $b = hex(substr($c,4,2))/255.;
    return ($r,$g,$b);
}

sub SetColor {
    my $cname = shift;
    my ($r,$g,$b) = rgb($cname);
    $page->setrgbcolor($r, $g, $b);
}


sub SetColorStroke {
    my $cname = shift;
    my ($r,$g,$b) = rgb($cname);
    $page->setrgbcolorstroke($r, $g, $b);
}

sub GnomonPath {
    my $short = shift;

    $page->newpath;
    $page->moveto($cx+$gnomon[0],$gy+$gnomon[1]);
    for ($i=1; $i<4-$short; $i++) {
        $page->lineto($cx+$gnomon[2*$i],$gy+$gnomon[2*$i+1]);
    }
    $page->lineto($cx,$gy);
    for ($i=3-$short; $i>0; $i--) {
        $page->lineto($cx-$gnomon[2*$i],$gy+$gnomon[2*$i+1]);
    }
    $page->closepath;
}

sub VerifyColor {
    my $c = shift;
    return defined($c) && length($c)==6 && !($c =~ /[^a-fA-F0-9]/);
}

sub DST {
    my $x = shift;
    my $y = shift;
    my $s1 = shift;
    my $s2 = shift;

    SetColorStroke("dst");
    SetColor("dst");
    $page->stringc($infoFont, $hourSize*.6, $x, $y, $s1);
    $page->stringc($infoFont, $hourSize*.6, $x, $y - $hourSize*.6, $s2);
    NormalColor();
}
