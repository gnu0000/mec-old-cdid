// Link program with winmm.lib library for MCI interface access.

#include <stdio.h>
#include <windows.h>
#include <GnuType.h>

typedef struct
   {
   int iMin;
   int iSec;
   int iFrame;
   int iTmp;
   } TFO, *PTFO;

TFO   tTRACK[100];
INT   iTRACKS = 0;
INT   iLEN    = 0;
DWORD iCDDB;

DWORD ComputeID ()
   {
   INT i, j, n, iCDDB_Sum;

   for (i=n=0; i < iTRACKS; i++)
      {
      iCDDB_Sum = 0;
      
      for (j = tTRACK[i+1].iMin*60 + tTRACK[i+1].iSec; j > 0; j /= 10) 
         iCDDB_Sum += (j % 10);
      n = n + iCDDB_Sum;
      }
   return ((n % 0xff) << 24 | iLEN << 8 | iTRACKS);
   }

int Cleanup (MCIDEVICEID wDeviceID)
   {
   mciSendCommand(wDeviceID, MCI_CLOSE, 0, 0);
   printf ("Abort.");
   exit (0);
   return 0;
   }

int GetInfo (PSZ pszDrive)
   {
   MCIDEVICEID      wDeviceID;
   MCI_OPEN_PARMS   mciOpenParms;
   MCI_SET_PARMS    mciSetParms;
   MCI_STATUS_PARMS mciStatusParms;
   int i, iTmp;

   mciOpenParms.lpstrDeviceType  = "cdaudio";
   mciOpenParms.lpstrElementName = pszDrive;
   if (mciSendCommand(0, MCI_OPEN, MCI_OPEN_TYPE | (pszDrive ? MCI_OPEN_ELEMENT : 0), (DWORD)&mciOpenParms))
      return 0;
   wDeviceID = mciOpenParms.wDeviceID;

   mciSetParms.dwTimeFormat = MCI_FORMAT_MSF;
   if (mciSendCommand(wDeviceID, MCI_SET, MCI_SET_TIME_FORMAT, (DWORD)&mciSetParms))
      return Cleanup (wDeviceID);

   mciStatusParms.dwItem = MCI_STATUS_NUMBER_OF_TRACKS;
   if (mciSendCommand(wDeviceID, MCI_STATUS, MCI_STATUS_ITEM, (DWORD)&mciStatusParms))
      return Cleanup (wDeviceID);
   iTRACKS = mciStatusParms.dwReturn;

   for(i=1; i<=iTRACKS; i++) 
      {
      mciStatusParms.dwItem  = MCI_STATUS_POSITION;
      mciStatusParms.dwTrack = i;
      if (mciSendCommand(wDeviceID, MCI_STATUS, MCI_STATUS_ITEM | MCI_TRACK, (DWORD)&mciStatusParms))
         return Cleanup (wDeviceID);

      // save track position in MSF format
      tTRACK[i].iFrame = MCI_MSF_FRAME (mciStatusParms.dwReturn);
      tTRACK[i].iSec   = MCI_MSF_SECOND(mciStatusParms.dwReturn);
      tTRACK[i].iMin   = MCI_MSF_MINUTE(mciStatusParms.dwReturn);
      tTRACK[i].iTmp   = tTRACK[i].iMin*60*75 + tTRACK[i].iSec*75 + tTRACK[i].iFrame;
      }

   mciStatusParms.dwItem = MCI_STATUS_LENGTH;
   mciStatusParms.dwTrack = iTRACKS;
   if (mciSendCommand(wDeviceID, MCI_STATUS, MCI_STATUS_ITEM | MCI_TRACK, (DWORD)&mciStatusParms))
      return Cleanup (wDeviceID);

   iTmp  = tTRACK[iTRACKS].iTmp +                      // start frame
           MCI_MSF_FRAME (mciStatusParms.dwReturn)+    // len
           MCI_MSF_SECOND(mciStatusParms.dwReturn)*75+
           MCI_MSF_MINUTE(mciStatusParms.dwReturn)*75*60+
           1; // win bug

   tTRACK[0].iTmp    = iTmp;
   tTRACK[0].iFrame  = iTmp % 75;  iTmp /= 75;
   tTRACK[0].iSec    = iTmp % 60;  iTmp /= 60;
   tTRACK[0].iMin    = iTmp;

   mciSendCommand(wDeviceID, MCI_CLOSE, 0, 0);

   iLEN  = (tTRACK[0].iMin * 60 + tTRACK[0].iSec) - 
           (tTRACK[1].iMin * 60 + tTRACK[1].iSec);
   return 0;
   }

void PrintInfo (void)
   {
   INT i;

   printf ("%08x %d ", iCDDB, iTRACKS);
   for (i=1; i<=iTRACKS; i++)
      printf ("%d ", tTRACK[i].iTmp);
   printf ("%d", iLEN);
   }

int main(void)
   {
   GetInfo(NULL);
   iCDDB = ComputeID ();
   PrintInfo ();
   }

