#!/usr/bin/env perl
# Drew Stephens <drew@dinomite.net> 2009
#
# Generate base reflectivity radar images from NOAA RIDGE data.
# http://www.srh.noaa.gov/srh/jetstream/doppler/ridge_download.htm
use strict;
use warnings;

# Radar site ID
my $siteID = 'LWX';

# Output image
my $outImage = 'base_reflectivity.jpg';

# Find ImageMagick's composite command
my $composite = `which composite`; chomp $composite;
die "plz2install ImageMagick" unless (-e $composite);

# Where RIDGE comes from
my $ridgeBase = 'http://radar.weather.gov/ridge';
# Layers to create the image with
my @mapLayers = (
    '_Topo_Short.jpg',
    '_Highways_Short.gif',
    '_County_Short.gif',
    '_City_Short.gif',
    '_Warnings_0.gif',
    '_N0R_Legend_0.gif',
);

# Remove the old base reflectivity image & get the new one
unlink $siteID . '_N0R_0.gif';
system('wget -q ' . $ridgeBase . '/RadarImg/N0R/' .  $siteID . '_N0R_0.gif');

# Use ImageMagick to make the new image
my $firstLayer = $siteID . shift @mapLayers;
grabLayer($firstLayer);
compose($siteID.'_N0R_0.gif', $firstLayer);
foreach my $layer (@mapLayers) {
    my $layer = $siteID . $layer;
    grabLayer($layer);
    compose($layer, $outImage);
}

sub grabLayer {
    my $layer = shift;

    return 1 if (-e $layer);

    if ($layer =~ /Warnings/) {
        system("wget -q $ridgeBase/Warnings/Short/" . $layer);
    } elsif ($layer =~ /Legend/) {
        system("wget -q $ridgeBase/Legend/N0R/" . $layer);
    } else {
        $layer =~ /^\w{3}_(\w+?)_.*\.(gif|jpg)/;
        my $dir = $1;
        # Thanks, NOAA.
        $dir = 'Cities' if ($dir eq 'City');

        system("wget -q $ridgeBase/Overlays/$dir/Short/" . $layer);
    }
}

sub compose {
    my ($top, $bottom) = @_;

    system("$composite -compose atop $top $bottom $outImage &> /dev/null");
}
