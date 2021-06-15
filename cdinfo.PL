#!/usr/bin/perl
#############################################################################

use strict;
use LWP;

my $QueryFile  = "Query.dat";
my $ReadFile   = "CDDB.dat";

MAIN:
   my @Fields = QueryCDDA () or MyExit ("Could not query CD info");
   print "Category: " . $Fields[1] . "\n";
   ReadCDDA (@Fields) or MyExit ("Could not read CD info");
   ShowCDDA ();
   exit (0);


sub QueryCDDA
   {
   print "Querying CD Database for ID...\n";

   my $cdInfo  = `CDID.EXE`;

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
   open (IN, "<$ReadFile");
   while (<IN>)
      {
      print "Title  : $1\n"  if /^DTITLE=(.*)/;
      print "Track$1: $2\n" if /^TTITLE(.*)=(.*)/;
      print "Error  : $1\n" if /^401(.*)/;
      }
   close (IN);
   }
