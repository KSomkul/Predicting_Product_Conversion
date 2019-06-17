/************************************************************************/
/* 										        						*/
/* Capstone Project: Predicting Glucose Monitoring Method Conversion 	*/
/*                                                                      */
/* Prepared By:				                                            */
/*     Kornkanok Somkul                                        			*/
/*     Shashi Bala Lnu                                                 	*/
/*     Peter Cao                                                    	*/                      
/* 							                                            */
/* National University                                                	*/
/* May 2019                                      						*/
/*     									                                */
/************************************************************************/

****************;
* IMPORT FILE  *; 
****************;
libname Cproject "~/Capstone/data";

FILENAME REFFILE '/home/kanoksomkul0/Capstone/data/capstone_project_data_v2.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=cproject.ads replace;
	GETNAMES=YES;
RUN;

************************************************************************;
* Define the macro variables for later use in the program              *;
************************************************************************;

%let data = cproject.ads;

%let data2 = cproject.clean;

*Group of continuous variables;
%let var_num = age insulin_usage times_testing;

*Group of date variables;
%let var_date = conversion_date start_date bill_date libre_prompt_date;

*Group of dichotomous variables;
%let var_cat = gender method diabetes_type elig_waiver pro_offer; 
			
*Group of categorical variables with multiple levels;
%let var_cat2 = brand state referral_type insurance;

*************;
* EXPLORING *; 
*************;

proc contents data= &data; run;

proc print data=&data (firstobs = 1 obs = 20); run;

** CHECKING DUPLICATE VALUES;
proc sql; select count(*) into : nobs from &data; quit; *48866 obs;
	
	* ~patientid;
proc sort data=&data out=work.clean nodupkey; by patientid; run;
proc sql; select count(patientid) into : nobs  from &data; quit; *48866 obs;

** CHECKING NUMERICAL VARIABLES;
proc means data= &data n nmiss min mean median max;
	var &var_num; 
	run; 

** CHECKING CATEGORICAL VARIABLES;
proc freq data=&data;
	table &var_cat;
	run;

proc freq data=&data order=freq nlevels;
	table &var_cat2;
	run;

** CHECKING DATE VARIABLES;
proc tabulate data=&data;
	var &var_date;
	table &var_date ,n nmiss (min mean median max)*f=mmddyy10.; 
	run;

** HISTOGRAM; 
proc univariate data=&data;
	var &var_num; 
	histogram / normal;
	run;

** BOXPLOT;

	* ~age;
ods graphics / reset width=6.4in height=4.8in imagemap;
proc sgplot data=&data;
	vbox age / fillattrs=(color=CX31fdca transparency=0.5) notches;
	yaxis grid;
	run;
	ods graphics / reset;

	* ~insulin_usage;
ods graphics / reset width=6.4in height=4.8in imagemap;
proc sgplot data=&data;
	vbox INSULIN_USAGE / fillattrs=(color=CX31fdca transparency=0.5) notches;
	yaxis grid;
	run;
	ods graphics / reset;

	* ~times_testing;
ods graphics / reset width=6.4in height=4.8in imagemap;
proc sgplot data=&data;
	vbox times_testing / fillattrs=(color=CX31fdca transparency=0.5) notches;
	yaxis grid label="TIMES_TESTING";
	run;
	ods graphics / reset;

****************;
* PREPARING	   *; 
****************;

** DATA STEP;
data work.ads; set &data;
	
	* Creating A New Dependent Variable: Cgm_conversion;
	cgm_conversion = conversion_date;
	if conversion_date in (' ') 
	then cgm_conversion = 0; 	/* patients who did not convert to cgm */
	else cgm_conversion = 1;	/* patients who converted to cgm */
	
	* Handling Categorical Variables;	
	* ~referral type from 35 to 3 categories;	
	referral_type2 = referral_type;
	if referral_type in ('ADS MARKETING' 'ADS EMPLOYEE' 'INSURANCE COMPANY' 'DEXCOM' 'TRADE SHOW' 'DME' 'GAS CARD REFERRAL' 
						 'INSURANCE COMPANY' 'MANUFACTURER' 'INTERNET' 'PATIENT REFERRAL') 
		then referral_type2 = 'COMMERCIAL';
	if referral_type in ('UHC Agent' 'ICA Agent' 'EDC Agent' 'MANAGED CARE BROK' 'INSURANCE BROKER') 
		then referral_type2 = 'AGENT';
	if referral_type in ('HOME HEALTH' 'HOSPITAL' 'PHARMACY' 'PHARMACY PARTNER' 'BLIND CENTER' 'MANAGED CARE'
						 'LTC' 'ASSISTED LIVING' 'CA MEDICAL GROUPS' 'MEDICAL GROUP' 'CLINIC' 'MEDICAID' 'MEDI-CAL'
						 'ENDOCRINOLOGIST' 'HEALTHCARE PROFES' 'PHYSICIAN' 'CDE') 
		then referral_type2 = 'HCA';
	if referral_type in ('MISCELLANEOUS' 'Unknown' 'ACQUISITION') 
		then referral_type2= 'OTHER';
		
	* ~insurance from 909 to 2 categories;
	insurance_2=insurance;
	if insurance IN (' ') then insurance_2='N/A';
	else if index(insurance,'MEDI-CAL') then insurance_2='GOVERNMENT INS';
	else if index(insurance,'MCAL') then insurance_2='GOVERNMENT INS';
	else if index(insurance,'MEDICAID CA') then insurance_2='GOVERNMENT INS';
	else if index(insurance,'MEDICARE') then insurance_2='GOVERNMENT INS';
	else if index(insurance,'TRICARE') then insurance_2='GOVERNMENT INS';
	else if index(insurance,'CHAMP VA') then insurance_2='GOVERNMENT INS';
	else if index(insurance,'DUAL') then insurance_2='GOVERNMENT INS';
	else if index(insurance,'MERIDIAN') then insurance_2='GOVERNMENT INS';
	else if index(insurance,'MEDICAID MO') then insurance_2='GOVERNMENT INS';
	else if index(insurance,'MEDICAID OR') then insurance_2='GOVERNMENT INS';
	else if index(insurance,'MEDICAID SC') then insurance_2='GOVERNMENT INS';
	else insurance_2='COMMERCIAL INS';
	
	* ~brands from 20 to 7 categories;
	strip_brand = brand;
	IF brand IN (' ')
		THEN strip_brand='N/A';
	IF brand IN ('ASSURE PLATINUM STRIPS 50CT' 'EMBRACE STRIPS 50CT' 'EVENCARE G3 STRIPS 50CT' 'NOVAMAX STRIPS 50CT' 'RETAIL PHARMACIST CHOICE STRIP')
		THEN strip_brand='OTHER';
	IF brand IN ('CONTOUR NEXT STRIPS 50CT' 'CONTOUR STRIPS 50CT' 'RETAIL CONTOUR NEXT STRIPS 50C' 'RETAIL CONTOUR STRIPS 50CT') 
		THEN strip_brand='CONTOUR';
	IF brand IN ('FREESTYLE NEO STRIPS 25CT' 'FREESTYLE NEO STRIPS 50CT' 'RETAIL FREESTYLE LITE STRIPS 1') 
		THEN strip_brand='FREESTYLE';
	IF brand IN ('MEDI-CAL TRUE METRIX STRIPS 50' 'RETAIL TRUE METRIX STRIPS 100C' 'RETAIL TRUE METRIX STRIPS 50CT' 'TRUE METRIX STRIPS 50CT' 'TRUE RESULT STRIPS 50CT') 
		THEN strip_brand='TRUE';
	IF brand IN ('PRODIGY ALL-IN-ONE STRIPS 50CT') 
		THEN strip_brand='PRODIGY';
	IF brand IN ('UNISTRIP STRIPS 50CT') 
		THEN strip_brand='UNISTRIP';
	IF brand IN ('RETAIL GUIDE STRIPS 50CT') 
		THEN strip_brand='ACCU-CHEK';
	
	* ~states 
		Categorizing state into Medicare Jurisdictions: A, B, C, & D
		Adding 'ny' and 'sd' into the "A" category;
	IF state IN ('CT' 'DE' 'DC' 'ME' 'MD' 'MA' 'NH' 'NJ' 'NY' 'ny' 'PA' 'RI' 'VT') THEN MEDIJURI='A';  
	IF state IN ('IL' 'IN' 'KY' 'MI' 'MN' 'OH' 'WI') THEN MEDIJURI='B'; 
	IF state IN ('AL' 'AR' 'CO' 'FL' 'GA' 'LA' 'MS' 'NM' 'NC' 'OK' 'PR' 'SC' 'TN' 'TX' 'VI' 'VA' 'WV') THEN MEDIJURI='C';  
	IF state IN ('AK' 'AS' 'AZ' 'CA' 'GU' 'HI' 'ID' 'IA' 'KS' 'MO' 'MT' 'NE' 'NV' 'ND' 'MP' 'OR' 'SD' 'sd' 'UT' 'WA' 'WY') THEN MEDIJURI='D';  

	* ~method;
	method_2 = method;
	if method in ('on CGM') then method_2 = 'CGM';
	else method_2 = 'SMBG';
	
	* Handling Continuous Variables;		
	* ~age
		Categorizing age into 3 levels:
		1.Children and young adults (1-26)
		2.Adults(27-65)
		3.Seniors(65+);
	if 1<=age<27  then age_cat = 1;
	if 27<=age<65  then age_cat = 2;
	if age>=65  then age_cat = 3;
	
	* ~insulin_usage
		Categorizing insulin age into 4 levels;
	if insulin_usage = 0 then insulin_cat = 0;  	 /*patients who did not inject insulin*/
	else if 1<=insulin_usage<6 then insulin_cat = 1; /*patients who injected insulin 1-6 times*/
	else if insulin_usage>=6 then insulin_cat = 2;	 /*patients who injected insulin more than 6 times*/
	else insulin_cat = 9; 	

	* Handling Date Variables;	
	* ~libre_prompt_date;
	if libre_prompt_date in (.) then libre_prompt = 0;
	else libre_prompt = 1; *creating a new cat var;
	
	* ~start_date & bill_date
		transforming start_date & bill_date into time form variables;
	member_inyears = round(yrdif(start_date, '30apr2019'd, 'Actual'),.1);
	last_bill_indays = round(datdif(bill_date, '30apr2019'd, 'Actual'),.1);
run;

	* Viewing Data Step Results;
proc freq data=work.ads order=freq;
	table CGM_Conversion referral_type2 insurance_2 strip_brand MEDIJURI age_cat insulin_cat libre_prompt method_2;
	run;
	
proc univariate data=work.ads;
	var member_inyears last_bill_indays; histogram;
	run;

** IMPUTATION;

	* Median imputation on times_testing due to ordinality;
proc stdize data=work.ads out=work.out
    oprefix=Orig_			/* prefix for original variables */
    reponly					/* only replace; do not standardize */
   	method=median;			/* or MEAN, MINIMUM, MIDRANGE, etc. */
  	var times_testing;		/* you can list multiple variables to impute */
	run;

	* Viewing Imputation Result;
proc univariate data=work.out;
	var times_testing; histogram / normal;
	run;

** DATA TRANSFORMATION;

	* ~times_testing;
data work.transform; set work.out;
	if  times_testing ne 0 then do;
		sqrt_times_test = sqrt(times_testing);
		sq_times_test=(times_testing*times_testing);
		log_times_test = log(times_testing);
		inv_times_test = 1/(times_testing);
		inv_sqrt_times_test= 1/(sqrt(times_testing));
		inv_sq_times_test= 1/(times_testing*times_testing);
		end;
	else do;
		sqrt_times_test = 0;
		sq_times_test=0;
		log_times_test = 0;
		inv_times_test = 0;
		inv_times_test=0;
		inv_times_test=0;
		end;
run;

	*Viewing The Transformation Results;
proc univariate data=work.transform nextrobs=10 normal; 
	var sqrt_times_test 
		sq_times_test 
		log_times_test 
		inv_times_test 
		inv_sqrt_times_test
		inv_sq_times_test;
	histogram  / normal;
	run; 


** ADDING LABELS;
data work.clean; set work.transform;;
	label referral_type2 = 'Type of referrals';
	label MEDIJURI = 'DME Jurisdiction Map as of October 2017';
	label elig_waiver = 'Eligibility Waiver';
	label pro_offer = 'Patient reorder opportunity offer';
	label diabetes_type = 'Type of diabetes: T1D or T2D';
	label gender = 'Gender: Male or female';
	label insurance_2 = 'Type of insurance';
	label strip_brand = 'Brand of testing strips';
	label age_cat = 'Age category';
	label method_2 = 'Type of method: SMBG or CGM';
	label CGM_conversion = 'CGM conversion: 0 or 1';
	label insulin_cat = 'Number of insulin injections per day';
	label libre_prompt = 'Prompted to use Libre';
	label times_testing = 'Finger pricks per day';
	label sqrt_times_test = 'Time pricked finger with the square root unit';
	label sq_times_test = 'Time pricked finger with the square unit';
	label log_times_test = 'Time pricked finger with the log unit';
	label inv_times_test = 'Time pricked finger with the inverse unit';
	label inv_sqrt_times_test = 'Time pricked finger with the inverse of square root unit';
	label inv_sq_times_test = 'Time pricked finger with the inverse of square unit';
	label Orig_times_testing = 'Original times patients pricked finger per day';
run;

proc contents data=work.clean; run;

** SAVE THE ClEAN DATA INTO CPROJECT LIBRARY;
data cproject.clean; set work.clean; run;


*********************;
* INVESTIGATION		*; 
*********************;

** THE CHI-SQUARE TEST FOR INDEPENDENCE;

	* Table 1: Relationships Between Voi And All Other Predictor Variables;
proc freq data=&data2; * table 1;
	tables (gender MEDIJURI age_cat  
	diabetes_type elig_waiver pro_offer
	libre_prompt insulin_cat  strip_brand insurance_2) * referral_type2/ chisq;
	where insurance_2 notin ('N/A') and referral_type2 notin ('OTHER');
	run;

	* Table 2:	Relationships Between All Predictor Variables And Dependent Variable;
proc freq data=&data2; * table 2;
	tables (referral_type2 gender MEDIJURI age_cat  
	diabetes_type elig_waiver pro_offer
	libre_prompt insulin_cat  strip_brand insurance_2) * CGM_Conversion/ chisq;
	where insurance_2 notin ('N/A') and referral_type2 notin ('OTHER');
	run;

** T-TEST;

	*Comparing the means between converting patients and non-coverting patients;
proc sort data=&data2;
  by cgm_conversion;
	run;

proc ttest data=&data2;
	class cgm_conversion;
    var times_testing member_inyears last_bill_indays;   
	run;

** MULTICOLLINEARITY;

	*Changing Categorical Variables to Numeric;
data work.checkvif; set &data2;

	if referral_type2 = 'COMMERCIAL' then referral_type2_num = 1;
	if referral_type2 = 'AGENT' then referral_type2_num = 2;
	if referral_type2 = 'HCA' then referral_type2_num = 3;
	if referral_type2 = 'OTHER' then referral_type2_num = 4;
	
	if gender = 'male' then gender_num = 1;
	if gender = 'female' then gender_num = 2;
	
	if MEDIJURI = 'A' then MEDIJURI_num = 1;
	if MEDIJURI = 'B' then MEDIJURI_num = 2;
	if MEDIJURI = 'C' then MEDIJURI_num = 3;
	if MEDIJURI = 'D' then MEDIJURI_num = 4;
	
	if diabetes_type = 'Type I' then Diabetes_type_num = 1;
	if diabetes_type = 'Type II' then Diabetes_type_num = 2;
	
	if elig_waiver = 'not on waiver' then elig_waiver_num = 1;
	if elig_waiver = 'on waiver' then elig_waiver_num = 2;
	
	if pro_offer = 'compliant' then pro_offer_num = 1;
	if pro_offer = 'noncompliant' then pro_offer_num = 2;
	
	if insurance_2 = 'GOVERNMENT INS' then insurance_num = 1;
	if insurance_2 = 'COMMERCIAL INS' then insurance_num = 2;
	if insurance_2 = 'N/A' then insurance_num = 3;
	
	if strip_brand='N/A' then strip_brand_num = 1;
	if strip_brand='OTHER' then strip_brand_num = 2;
	if strip_brand='CONTOUR' then strip_brand_num = 3;
	if strip_brand='FREESTYLE' then strip_brand_num = 4;
	if strip_brand='TRUE' then strip_brand_num = 5;
	if strip_brand='PRODIGY' then strip_brand_num = 6;
	if strip_brand='UNISTRIP' then strip_brand_num = 7;
	if strip_brand='ACCU-CHEK' then strip_brand_num = 8;
	
	if method_2 ='CGM' then method_num = 1;
	if method_2 ='SMBG' then method_num = 2;
run;

proc contents data=checkvif; run;

proc freq data=work.checkvif;
 	table strip_brand_num pro_offer_num elig_waiver_num diabetes_type_num 
 	medijuri_num gender_num referral_type2_num insurance_num insulin_cat method_num;
	run;

	*Correlation matrix w/ VIF;
proc reg data=work.checkvif;
  model cgm_conversion = strip_brand_num pro_offer_num elig_waiver_num diabetes_type_num 
 	medijuri_num gender_num referral_type2_num libre_prompt age_cat insurance_num insulin_cat 
 	times_testing member_inyears last_bill_indays method_num/ vif;
  title 'VIF table';
	run;
	quit;

** SAVE THE NEW NUMERIC DATA INTO THE CLEAN DATASET;
data cproject.clean; set work.checkvif; run;

*********************;
* EXPLORING ROUND2	*; 
*********************;

	*~cgm_conversion;
ods graphics/ reset width=3in height=5in imagemap attrpriority=color;
proc sgplot data=&data2;
  styleattrs datacolors=(navy orange )
  			 datacontrastcolors=(navy orange)
             datalinepatterns=(solid);
	vbar cgm_conversion / datalabel stat=percent group=cgm_conversion CATEGORYORDER=respasc;
	xaxis grid label='cgm conversion';
	run;
	ods graphics / reset;
	
	* ~strip_brand;
ods graphics / reset width=5in height=4.8in imagemap;
proc sgplot data=&data2;
	vbar strip_brand / datalabel group=strip_brand CATEGORYORDER=RESPASC;
	xaxis grid;
	xaxis grid label='Brand of testing strips';
	run;
	ods graphics / reset;

	* ~referral_type2;
ods graphics/ reset width=5in height=5in imagemap attrpriority=color;
proc sgplot data=&data2;
	vbar referral_type2 / datalabel group=referral_type2 CATEGORYORDER=respasc;
	xaxis grid label='TYPE OF REFERRALS';
	run;
	ods graphics / reset;

	* ~medijuri;
ods graphics/ reset width=5in height=5in imagemap attrpriority=color;
proc sgplot data=&data2;
	vbar medijuri / datalabel group=medijuri CATEGORYORDER=respasc;
	xaxis grid label='Medicare jurisdiction';
run;
ods graphics / reset;

	* ~insurance_2;
ods graphics/ reset width=5in height=5in imagemap attrpriority=color;
proc sgplot data=&data2;
  	styleattrs DATACOLORS=(orange navy gray )
  			 DATACONTRASTCOLORS=(orange navy gray )
             datalinepatterns=(solid);
	vbar insurance_2 / datalabel group=insurance_2 CATEGORYORDER=respasc;
	xaxis grid label='Insurance';
run;
ods graphics / reset;

	*~ libre_prompt group by cgm_conversion;
ods graphics/ reset width=5in height=5in imagemap attrpriority=color;
proc sgplot data=&data2;
  	styleattrs DATACOLORS=(orange navy )
  			 DATACONTRASTCOLORS=(orange navy )
             datalinepatterns=(solid);
	vbar libre_prompt / datalabel stat=percent group=cgm_conversion groupdisplay=cluster CATEGORYORDER=respasc;
	xaxis grid label='libre prompt by CGM conversion';
	run;
	ods graphics / reset;

	* ~method_2 group by cgm_conversion;
ods graphics/ reset width=5in height=5in imagemap attrpriority=color;
proc sgplot data=&data2;
 	styleattrs DATACOLORS=(navy orange)
  			 DATACONTRASTCOLORS=(navy orange)
             datalinepatterns=(solid);
	vbar method_2 / datalabel stat=percent group=cgm_conversion groupdisplay=cluster CATEGORYORDER=respasc;
	xaxis grid label='Type of methods by CGM conversion';
	run;
	ods graphics / reset;


*********************;
* DATA SPLITTING	*; 
*********************;

**CROSS VALIDATION - 75/25 split;

%let target_var = cgm_conversion;
	
data work.split; 
	set &data2;
	where &target_var in(1,0); 
run;

	* sort data because will use strata option in SURVEYSELECT;
proc sort data=work.split; by &target_var; run;
	
proc surveyselect noprint data=work.split 
	samprate=.75 
	out=work.model_sample seed=1111 outall;
	strata &target_var; 
	 *Samprate = % of the data that should be "selected"/ 
	  outall = output all data to work.model_sample;
	run; 
	 
proc freq data=work.model_sample;
	table &target_var*selected; 
	run;
		
	*Create separate Training and Validation datasets;
data work.train work.validate;
	set work.model_sample;
	if selected = 1 then output train;
					else output validate;
run;

*************;
* MODELING	*; 
*************;

/* THE NULL HYPOTHESIS = THERE IS NO ASSOCIATION BETWEEN CONVERTING PATIENTS AND REFERRALS
   AFTER CONTROLLING FOR CLINICAL AND DEMOGRAPHIC CHARACTERISTICS */

** FULL LOGISTIC REGRESSION MODEL WITH ALL ELIGIBLE VARIABLES;	
PROC LOGISTIC DATA = work.validate;
	CLASS CGM_Conversion (REF='0') referral_type2 (REF='AGENT') gender (REF='female') MEDIJURI (REF='D') age_cat (REF='3')
	diabetes_type (REF='Type II') elig_waiver (REF='not on waiver') pro_offer (REF='compliant') 
	insulin_cat (REF='0') strip_brand (REF='N/A') insurance_2 (REF='GOVERNMENT INS')/ PARAM=REF; 
	MODEL CGM_Conversion = 	referral_type2 gender MEDIJURI age_cat diabetes_type 
							elig_waiver pro_offer insulin_cat strip_brand insurance_2 orig_times_testing/ stb rl lackfit;
	score data=validate out=validpred fitstat;
	ROC 'Uninformative';
	roccontrast reference('Uninformative') /estimate;
	TITLE 'LOGISTIC REGRESSION MODEL WITH ALL ELIGIBLE VARIABLES';
	 * diabetes_type & elig_waiver are insignificant from T3 AoE table;
	RUN; 

** OPTIMIZED LOGISTIC REGRESSION MODEL - training set;
ods graphics on;
PROC LOGISTIC DATA = work.train;
	CLASS CGM_Conversion (REF='0') referral_type2 (REF='AGENT') gender (REF='female') 
		  MEDIJURI (REF='A') age_cat (REF='3') insurance_2 (REF='GOVERNMENT INS')/ PARAM=REF; 
	MODEL CGM_Conversion = 	referral_type2 gender MEDIJURI age_cat 
							insurance_2 / ctable stb rl lackfit;
							where insurance_2 notin ('N/A') and referral_type2 notin ('OTHER');
							score data=train out=trainpred fitstat;
	TITLE 'OPTIMIZED LOGISTIC REGRESSION MODEL - TRAINING SET'; 
	 *Without: times_testing insulin_cat strip_brand diabetes_type elig_waiver & pro_offer;
	RUN;

** LOGISTIC REGRESSION MODEL - validation set ; 
ods graphics on;
PROC LOGISTIC DATA = work.validate;
	CLASS CGM_Conversion (REF='0') referral_type2 (REF='AGENT') gender (REF='female') 
		  MEDIJURI (REF='D') age_cat (REF='3') insurance_2 (REF='GOVERNMENT INS')/ PARAM=REF; 
	MODEL CGM_Conversion = 	referral_type2 gender MEDIJURI age_cat 
							insurance_2 / ctable stb rl lackfit;
							where insurance_2 notin ('N/A') and referral_type2 notin ('OTHER');
							score data=validate out=validpred fitstat;
	TITLE 'OPTIMIZED LOGISTIC REGRESSION MODEL - VALIDATION SET'; 
	 *Without: times_testing insulin_cat strip_brand diabetes_type elig_waiver & pro_offer;
	RUN;

** OUTPUTTING THE PROPENSITY FOR GROUP SELECTION;
PROC LOGISTIC DATA = work.validate; *Must switch out training and validation sets;
	CLASS  referral_type2 (REF='AGENT')  age_cat (REF='3') gender (REF='female') MEDIJURI (REF='A') / PARAM=REF; 
	MODEL referral_type2 =  age_cat gender MEDIJURI; *Propensity based on age, gender and region;
	where insurance_2 notin ('N/A') and referral_type2 notin ('OTHER');
	OUTPUT OUT= ALLPROPEN PROB=PROPENSITYREF; *OUTPUT THE PROPENSITY FOR GROUP SELECTION;
	TITLE;
	RUN;

*LOGISTIC REGRESSION MODEL WITH PROPENSITY VARIABLE;
PROC LOGISTIC DATA = ALLPROPEN;
	CLASS CGM_Conversion (REF='0') referral_type2 (REF='AGENT') gender (REF='female') 
		  MEDIJURI (REF='D') age_cat (REF='3') insurance_2 (REF='GOVERNMENT INS')/ PARAM=REF; 
	MODEL CGM_Conversion = 	referral_type2 gender MEDIJURI age_cat 
							 insurance_2 PROPENSITYREF/ ctable stb lackfit;
							where insurance_2 notin ('N/A') and referral_type2 notin ('OTHER');
							score data=allpropen out=allproppred fitstat;
	TITLE 'PROPENSITY ADJUSTED LOGISTIC REGRESSION MODEL';
	RUN;

*Decision Tree w/ training set, no prune;
proc hpsplit data=work.train;
	input 	referral_type2 gender MEDIJURI age_cat insurance_2 ;
	target CGM_Conversion;
	prune none;
	where insurance_2 notin ('N/A') and referral_type2 notin ('OTHER');
	TITLE 'DECISION TREE TRAINING SET, NO PRUNE';
	run;

*Decision Tree w/ training set and pruning;
proc hpsplit data=work.train;
	input 	referral_type2 gender MEDIJURI age_cat insurance_2 ;
	target CGM_Conversion;
	prune costcomplexity;
	where insurance_2 notin ('N/A') and referral_type2 notin ('OTHER');
	TITLE 'DECISION TREE TRAINING SET WITH COST COMPLEXITY PRUNE';
	run;

*Decision Tree w/ validation set, no prune;
proc hpsplit data=work.validate;
	input 	referral_type2 gender MEDIJURI age_cat insurance_2 ;
	target CGM_Conversion;
	prune none;
	where insurance_2 notin ('N/A') and referral_type2 notin ('OTHER');
	TITLE 'DECISION TREE VALIDATION SET, NO PRUNE';
	run;


*Decision Tree w/ validation set and pruning;
proc hpsplit data=work.validate;
	input 	referral_type2 gender MEDIJURI age_cat insurance_2 ;
	target CGM_Conversion;
	prune costcomplexity;
	where insurance_2 notin ('N/A') and referral_type2 notin ('OTHER');
	TITLE 'DECISION TREE VALIDATION SET WITH COST COMPLEXITY PRUNE';
	run;

*LDA w/ training set;
proc discrim data=work.train distance; *other options: anova manova;
	class CGM_Conversion ;
	var  age_cat medijuri_num gender_num referral_type2_num insurance_num;
	where insurance_num notin (3) and referral_type2_num notin (4);
	TITLE 'LINEAR DISCRIMINANT ANALYSIS - TRAINING SET';
	run;

*LDA w/ validation set;
proc discrim data=work.validate distance;
	class CGM_Conversion ;
	var age_cat medijuri_num gender_num referral_type2_num insurance_num;
	where insurance_num notin (3) and referral_type2_num notin (4);
	TITLE 'LINEAR DISCRIMINANT ANALYSIS - VALIDATION SET';
	run;
	

****************;
* EXPORT FILE  *; 
****************;

proc export DATa=cproject.clean
outfile="~/Capstone/data"
dbms=XLS replace;
run;

















