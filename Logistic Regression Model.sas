*Hackathon SAS;
*Code by: Yash Bhatnagar;

*Importing the dataset;
FILENAME REFFILE '/folders/myfolders/Hackathon/train.csv';
PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.traindata;
	GETNAMES=YES;
RUN;

*Checking variable type of the import dataset;
proc contents data=trainData varnum;
run;

*Checks if any variables have missing values;
proc means data=trainData nmiss;
run;

*Txt_Policy_Year has 6 missing values, therefore doing suitable treatment;
data tmp;
set traindata;
	if Txt_Policy_Year = ' ' then delete;
run;
proc means data=tmp nmiss;
run;

/*Checking for outlier*/
proc univariate data=tmp;
run;

*Found some outliers, now treating the same;
data tmp2;
set tmp;
	if Txt_Policy_Code >2 then Txt_Policy_Code = 2;
	if Num_Vehicle_Age >12 then Num_Vehicle_Age=12;
	if Num_IDV >2160000 then Num_IDV  = 2160000;
	if Num_IDV <16000 then Num_IDV =16000;
	if Txt_TAC_NOL_Code <5 then Txt_TAC_NOL_Code =5;
	if Num_Net_OD_Premium >25076 then Num_Net_OD_Premium = 25076;
	if Num_Net_OD_Premium <149 then Num_Net_OD_Premium = 149;
run;

/*Checking for outlier after treating*/
proc univariate data=tmp2;
run;

*Converting 'Drv_Claim_status' into a boolean value as Rejected -1, closed-0;
data t1;
set tmp2;
	if Drv_Claim_Status = 'REJECTED' then Drv_Claim_Status = 1;
	else Drv_Claim_Status = 0;
run;
data t1;
set t1;
	target = int(Drv_Claim_Status);
run;

*Distribution by categorical variables;
%let cat = Txt_Claim_Year Txt_Policy_year Txt_Location_RTA Txt_Colour_Vehicle Txt_Place_Accident Drv_Claim_status;
proc freq data=t1;
	table  &cat/ nocum;
	title 'Percentage distribution of categorical variables';
run;

*Finding correlation among variables to find highly correlated variables;
proc corr data=t1 NOPROB;
run;

*Logistic Regression Model;
%let var = Txt_Policy_Year Boo_Endorsement Txt_Class_Code Txt_Zone_Code Num_IDV Txt_CC_PCC_GVW_Code Txt_Permit_Code Txt_Nature_Goods_Code Txt_Road_Type_Code Txt_Vehicle_Driven_By_Code
Txt_Driver_Exp_Code Txt_Driver_Qualification_Code Txt_Incurred_Claims_Code Boo_TPPD_Statutory_Cover_only Date_Claim_Intimation Txt_TAC_NOL_Code Boo_OD_Total_Loss Boo_AntiTheft Boo_NCB  ;
proc logistic data=t1 descending outmodel=model;
	model target = &var / lackfit;
	output out = train_output xbeta = coeff stdxbeta = stdcoeff predicted = prob;
	store hack_log;
run;

*Importing test dataset;
FILENAME REFFILE '/folders/myfolders/Hackathon/Test.csv';
PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.test;
	GETNAMES=YES;
RUN;

*Calculating probability;
proc plm source=hack_log;
score data=test out=test_scored predicted=p / ilink;
run;

*Finding score;
data test_scored;
set test_scored;
DRV_CLAIM_STATUS = 0;
run;

data final;
set test_scored;
	if p > 0.5 then DRV_CLAIM_STATUS = 1;
	else DRV_CLAIM_STATUS = 0;
keep Uniquekey DRV_CLAIM_STATUS;
run;
