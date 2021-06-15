#!/usr/bin/perl
#############################################################################

use strict;
use LWP;

my $Prefix     = shift;       # 1st param is src filename prefix
my $TwoDigit   = shift;       # 2nd optional param is for 2 digit indexes

my $QueryFile  = "Query.dat";
my $ReadFile   = "CDDB.dat";

MAIN:
   my @Fields = QueryCDDA () or MyExit ("Could not query CD info");
   ReadCDDA (@Fields) or MyExit ("Could not read CD info");
   ShowCDDA ();
   exit (0);


sub QueryCDDA
   {
   print "Querying CD Database for ID...\n";

   my $cdInfo  = `c:\\bin\\CDID.EXE`;

   $cdInfo =~ tr/ /+/;
   my $Url = "http://us.cddb.com/~cddb/cddb.cgi?" .
            "cmd=cddb+query+" . $cdInfo .
            "&hello=craig+www.infotechfl.com+httptest+0.1" .
            "&proto=1";

   my $ua  = LWP::UserAgent->new();
   my $req = HTTP::Request->new(GET => $Url);
   my $res = $ua->request($req, $QueryFile);
   return 0 if !$res->is_success();

   open (IN, "<$QueryFile");
   $_ = <IN>;
   $_ = "200 " . <IN> if (/^211/);
   close (IN);

   MyExit ("Error: ". $_) if !(/^200/);
   unlink ($QueryFile);
   return split;
   }



sub ReadCDDA
   {
   my ($Junk, $Type, $CDID) = @_;

   print "Querying CD Database for Data...\n";

   my $Url = "http://us.cddb.com/~cddb/cddb.cgi?" .
            "cmd=cddb+read+". $Type ."+". $CDID .
            "&hello=craig+www.infotechfl.com+httptest+0.1" .
            "&proto=1";

   my $ua  = LWP::UserAgent->new;
   my $req = HTTP::Request->new(GET => $Url);
   my $res = $ua->request($req, $ReadFile);
   return $res->is_success();
   }


sub MyExit
   {
   print @_;
   exit (0);
   }


sub ShowCDDA
   {
   my ($Line, $DiskTitle, $TrkTitle, $DestPath);
   my ($TrkIndex, $Idx, $Src, $Dest);

   open (IN, "<$ReadFile");
   while (<IN>)
      {
      if (/^DTITLE=(.*)/ && !$DiskTitle)       # disk title
         {
         $DiskTitle = $1;
         $DiskTitle =~ tr/ './/d;
         $DiskTitle =~ tr/a-zA-Z0-9-/_/c;
         $DestPath  = "mp3\\$DiskTitle";
         printf "Creating directory: $DestPath\n";
         `md $DestPath`;
         }
      if (/^TTITLE(.*)=(.*)/)   # track title
         {
         MyExit ("bad file order") if (!$DiskTitle);

         $Idx      = $1+1;
         $TrkTitle = $2;
         $TrkTitle =~ tr/ './/d;
         $TrkTitle =~ tr/a-zA-Z0-9-/_/c;

         $TrkIndex = sprintf (($TwoDigit ? "%2.2d" : "%d"), $Idx);
         $Src = "$Prefix"."$TrkIndex.*";

         $TrkIndex = sprintf ("%2.2d", $Idx);
         $Dest= "$DestPath\\$TrkIndex"."_"."$TrkTitle.*";

         printf "$Src -> $Dest\n";
         `ren $Src $Dest`;
         }
      }
   close (IN);
   return 1;
   }
