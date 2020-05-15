/* 
 * Copyright (c) 2016, SAS Institute Inc., Cary, NC, USA, All Rights Reserved
 *
 * autoexec.sas
 *
 *    This autoexec file include sas files relevent to this application server.
 *
 *    Do NOT modify this file.  Any additions or changes should be made in 
 *    autoexec_usermods.sas.
 */

%macro includeifexists(includefile);
  %if %sysfunc(fileexist(&includefile)) %then
    %do;
      %include &includefile;
    %end;
%mend;

%macro enable_lockdown;
  %let lockdown_state="%sysget(BATCHSERVER_LOCKDOWN_ENABLE)";
  %if &lockdown_state = "1" %then
    %do;
       lockdown enable_ams=http email ftp hadoop java;
       lockdown path="CAS_CLIENT_SSL_CA_LIST";
       lockdown path="%sysget(SASCONFIG)/data";
       lockdown path="%sysget(config_home)";
       lockdown path="~";
       lockdown path="%sysget(HOME)";
    %end;
%mend;

%macro armcheck;
     %local SUBSYS;
	data _null_;
	    if envlen('ARM_SUBSYS') gt 0 then call symput('SUBSYS',sysget('ARM_SUBSYS'));
	run;
 	%if %length(&SUBSYS) NE 0 %then
 	%do;
      %if ( %UPCASE("&SUBSYS") EQ "ARM_PROC" or 
            %UPCASE("&SUBSYS") EQ "ARM_DSIO" or 
            %UPCASE("&SUBSYS") EQ "ARM_ALL" or
            %UPCASE("&SUBSYS") EQ "ARM_NONE" ) %then
      %do;
          %log4sas();
          %log4sas_logger(Perf.ARM);
          options armagent=log4sas armsubsys=(&SUBSYS);
      %end;
      %else %do;
          %put WARNING: Unknown ARM subsystem=[&SUBSYS] requested;
      %end;
     %end;
%mend armcheck;

%enable_lockdown;
%armcheck;

options cashost="&SYSHOSTNAME" casport=5570;

%includeifexists("%sysget(sas_autoexec_deployment)");
%include "%sysget(sas_autoexec_usermods)";
