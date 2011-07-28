#!/usr/bin/perl -w
# --
# bin/CheckSum.pl - a tool to compare changes in a installation
# Copyright (C) 2001-2008 OTRS AG, http://otrs.org/
# --
# $Id: CheckSum.pl,v 1.13 2008-07-13 23:14:11 martin Exp $
# --
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# --

use strict;
use warnings;

# use ../ as lib location
use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);
use lib dirname($RealBin) . "/Kernel/cpan-lib";

use vars qw($VERSION $RealBin);
$VERSION = qw($Revision: 1.13 $) [1];

use Getopt::Std;
use Digest::MD5 qw(md5_hex);

my $Start   = $RealBin . '/../';
my $Archive = '';
my $Action  = 'compare';
my %Compare = ();

# get options
my %Opts = ();
getopt( 'habd', \%Opts );
if ( $Opts{'h'} ) {
    print "CheckSum.pl <Revision $VERSION> - OTRS check sum\n";
    print "Copyright (c) 2001-2008 OTRS AG, http://otrs.org/\n";
    print "usage: CheckSum.pl -a create|compare [-b /path/to/ARCHIVE] [-d /path/to/framework]\n";
    exit 1;
}

if ( $Opts{'a'} && $Opts{'a'} eq 'create' ) {
    $Action = $Opts{'a'};
}
if ( $Opts{'d'} ) {
    $Start = $Opts{'d'};
}
if ( $Opts{'b'} ) {
    $Archive = $Opts{'b'};
}
else {
    $Archive = $Start . 'ARCHIVE';
}

if ( $Action eq 'create' ) {
    print "Writing $Archive ...";
    open( OUT, '>', $Archive ) || die "ERROR: Can't open: $Archive";
}
else {
    open( IN, '<', $Archive ) || die "ERROR: Can't open: $Archive";
    while (<IN>) {
        my @Row = split( /::/, $_ );
        chomp( $Row[1] );
        $Compare{ $Row[1] } = $Row[0];
    }
    close(IN);
}

my @Dirs = ();
R($Start);
for my $File ( sort keys %Compare ) {

    #    print "Notice: Removed $Compare{$File}\n";
    print "Notice: Removed $File\n";
}
if ( $Action eq 'create' ) {
    print " done.\n";
    close(OUT);
}

sub R {
    my ($In) = @_;

    my @List = glob("$In/*");
    for my $File (@List) {
        $File =~ s/\/\//\//g;
        if ( -d $File && $File !~ /CVS/ && $File !~ /^doc\// && $File !~ /^var\/tmp/ ) {
            R($File);
            $File =~ s/$Start//;

            #            print "Directory: $File\n";
        }
        else {
            my $OrigFile = $File;
            $File =~ s/$Start//;
            $File =~ s/^\/(.*)$/$1/;

            #            print "File: $File\n";
            if (
                $File !~ /Entries|Repository|Root|CVS|ARCHIVE/
                && $File !~ /^doc\//
                && $File !~ /^var\/tmp/
                )
            {
                my $Content = '';
                open( IN, '<', $OrigFile ) || die "ERROR: $!";
                while (<IN>) {
                    $Content .= $_;
                }
                close(IN);
                my $Digest = md5_hex($Content);
                if ( $Action eq 'create' ) {
                    print OUT $Digest . '::' . $File . "\n";
                }
                else {
                    if ( !$Compare{$File} ) {
                        print "Notice: New $File\n";
                    }
                    elsif ( $Compare{$File} ne $Digest ) {
                        print "Notice: Dif $File\n";
                    }
                    if ( defined( $Compare{$File} ) ) {
                        delete $Compare{$File};
                    }
                }
            }
        }
    }
    return 1;
}