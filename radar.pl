#!/usr/bin/env perl
# Drew Stephens <drew@dinomite.net> 2009
#
# Generate base reflectivity radar images from NOAA RIDGE data, just like I do
# at http://dinomite.net/~dinomite/wx/lwx
# see: http://www.srh.noaa.gov/srh/jetstream/doppler/ridge_download.htm
#
# Pair this with a cronjob, and you can have autogenerated, up-to-date
# radar images that are easy to pull up on a phone.  I use this crontab line:
# */5 * * * * cd /home/dinomite/public_html/wx/radar/lwx && /home/dinomite/public_html/wx/radar/lwx/radar.pl
use strict;
use warnings;

# Radar site ID; look this up at the RIDGE site above
my $siteID = 'MUX';

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

# Make the html file
my $htmlFile = 'index.html';
makeIndex() unless (-e $htmlFile);

# Remove the old base reflectivity image & get the new one
unlink $siteID . '_N0R_0.gif';
system('wget -q ' . $ridgeBase . '/RadarImg/N0R/' .  $siteID . '_N0R_0.gif');

# The first layer is special - we have to create the base image
my $firstLayer = $siteID . shift @mapLayers;
grabLayer($firstLayer);
compose($siteID.'_N0R_0.gif', $firstLayer);
# Subsequent layers are applied to the base image
foreach my $layer (@mapLayers) {
    my $layer = $siteID . $layer;
    grabLayer($layer);
    compose($layer, $outImage);
}

# Pull a layer from NWS RIDGE if it doesn't exist
sub grabLayer {
    my $layer = shift;

    # The Legend is the only layer that changes
    return 1 if (-e $layer && $layer !~ /Legend/);

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

# Do the image compositing using ImageMagick
sub compose {
    my ($top, $bottom) = @_;

    system("$composite -compose atop $top $bottom $outImage 2>&1 > /dev/null");
}

# Write the index file
sub makeIndex {
    my $content;

    # Slurp the whole file
    {
        local $/;
        $content = <DATA>;
    }
    $content =~ s/SITE_ID/$siteID/;

    open(my $fh, '>', $htmlFile) or die $!;

    print $fh $content;
}

__DATA__
<html>

<head>
    <title>NWS SITE_ID Radar</title>
    <meta http-equiv='refresh' content='300'>
</head>

<body>
<table>
       <tr>
               <td><img src="base_reflectivity.jpg"></td>
               <td><img src="base_reflectivity.jpg"></td>
       </tr>
</table>
</body>

</html>
