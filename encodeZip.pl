open ZIP, ">zipcodes.dat";
binmode(ZIP);

while(<>) {
    s/[\r\n]+//g;
    split /\t/;
    $n = $_[0]+0;
    $long[$n] = $_[5];
    $lat[$n] = $_[6];
}

for $n (600..99999) {
    if (!defined($long[$n])) {
        print ZIP pack("NN", 0xFFFFFFFF, 0xFFFFFFFF);
    }
    else {
        print ZIP pack("NN", int(abs($long[$n])*1000000), int(abs($lat[$n])*1000000));
    }
}
close(ZIP);
