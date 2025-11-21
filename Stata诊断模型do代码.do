

************************************************************************
**************诊断Logistic回归临床预测模型（松哥统计）******************
************************************************************************
*安装一个可以输出统计表格的包！
*ssc install asdoc, replace


**如何用stata直接进行数据拆分,stata16及以上才可以
sysuse "auto.dta", clear //调用系统数据
splitsample,generate(sample) split(.75 .25) rseed(12345) //将数据随机按照75%和25%分成两部分，前者为训练集用于回归，后者为验证集用于验证，rseed(12345)是为了让结果可重复

label define slabel 1 "Training" 2 "Validation"
label values sample slabel

tabulate sample

************************************************************************
*先单
logit hypoglycemia course_of_disease  if dataset==1,or

logit hypoglycemia  hyperlipidemia  if dataset==1,or

logit hypoglycemia  treat_time  if dataset==1,or

logit hypoglycemia  gender  if dataset==1,or

logit hypoglycemia  hypertension  if dataset==1,or

logit hypoglycemia  i.marital_status  if dataset==1,or


*后多
logit hypoglycemia  course_of_disease hyperlipidemia treat_time gender  if dataset==1,or



*********************Step1 develop model********************************

**enter**先单15个因素，如果觉得太长，可以用X1-X40

logit hypoglycemia course_of_disease hyperlipidemia treat_time education gender tg hdlc ins c_peptide age bun rbg grf fbg bmi if dataset==1

*可以用///进行分段，但必须全选才能执行
logit hypoglycemia course_of_disease hyperlipidemia treat_time education gende ///
tg hdlc ins c_peptide age bun rbg grf fbg bmi if dataset==1



*在语句后面加//，表示语句内注释
est store s1   //保存结果

**step wise**
sw,pe(0.1):logit hypoglycemia course_of_disease hyperlipidemia treat_time education gender tg hdlc ins c_peptide age bun rbg grf fbg bmi if dataset==1,or
est store s2

sw,pr(0.1):logit hypoglycemia course_of_disease hyperlipidemia treat_time education gender tg hdlc ins c_peptide age bun rbg grf fbg bmi if dataset==1,or
est store s3

sw,pe(0.05)pr(0.1):logit hypoglycemia course_of_disease hyperlipidemia treat_time education gender tg hdlc ins c_peptide age bun rbg grf fbg bmi if dataset==1,or
est store s4


**SPSS Back LR_9**

logit hypoglycemia hyperlipidemia treat_time education hdlc ins c_peptide bun rbg fbg if dataset==1
est store s5

**SPSS forward LR_7**
logit hypoglycemia treat_time education hdlc ins c_peptide rbg fbg if dataset==1
est store s6
------------------------



**输出AIC&BIC******
est stats s1 s2 s3 s4 s5 s6


**AIC比较***Likelihood ratio test between s4 and s6**
lrtest s1 s5

lrtest s5 s6

lrtest s1 s6

*******************************************************************************
*******************************step2 model validation**************************
*若前面已经存储了某个模型，如下就可以呈现该模型，也可以重新做一遍。
*est replay s5
*******************************************************************************

logit hypoglycemia hyperlipidemia treat_time education hdlc ins c_peptide bun rbg fbg if dataset==1

logit hypoglycemia hyperlipidemia treat_time education hdlc ins c_peptide bun rbg fbg if dataset==1,or

**保存预测值
*注意，此步和SPSS一样，会根据产生的模型对dev和val数据同时进行预测
*此步必须做，只有预测出P值，方可进行后续模型验证

predict prob,pr




**2.**区分度验证

**2.1*训练集的AUC analysis

roctab hypoglycemia prob if dataset==1



**2.2***训练集ROC分析
roctab hypoglycemia prob if dataset==1,graph


**2.3*验证集AUC analysis

roctab hypoglycemia prob if dataset==0


**2.4验证集ROC分析
roctab hypoglycemia prob if dataset==0,graph



**2.5多条ROC曲线
*roccomp y p1 p2,graph


logit hypoglycemia hyperlipidemia treat_time education hdlc ins if dataset==1

predict prob2,pr

roccomp hypoglycemia prob prob2 if dataset==1,graph

roccomp hypoglycemia prob prob2 if dataset==0,graph

***************************************************************
**************************************************************
**3.校准度分析calibration

**3.1训练集hosmer lemeshow检验
hl hypoglycemia prob if dataset==1

**3.2训练集校准曲线calibration plot
hl hypoglycemia prob if dataset==1,plot


**3.3验证集校准度calibration

hl hypoglycemia prob if dataset==0

**3.4*验证集校准度calibration plot
hl hypoglycemia prob if dataset==0,plot


*************************校准曲线加强版*****************************************
*半路出家
logit hypoglycemia hyperlipidemia treat_time education hdlc ins c_peptide bun rbg fbg if dataset==1

predict prob,pr

*训练集
pmcalplot prob hypoglycemia if dataset==1
pmcalplot prob hypoglycemia if dataset==1,ci

*验证集
pmcalplot prob hypoglycemia if dataset==0
pmcalplot prob hypoglycemia if dataset==0,ci

*more modify
pmcalplot prob hypoglycemia if dataset==1, ci nospike nostatistics

pmcalplot prob hypoglycemia if dataset==1, ci nospike nostatistics xtitle("Predicted probability", size(medsmall)) ytitle("Observed frequency", size(medsmall)) legend(off)


*可以根据临床已有的界值，制作calibration plot，如本例0.05,0.15和0.5
pmcalplot prob hypoglycemia if dataset==1, cut(.05 .15 .5) ci keep


********************************************************************************
**4.临床决策曲线分析DCA
********************************************************************************
*4.1训练集临床决策曲线

*ssc install dca

dca hypoglycemia prob if dataset==1


*4.2验证集临床决策曲线
dca hypoglycemia prob if dataset==0

*4.3*决策曲线优化
dca hypoglycemia prob if dataset==1, smooth xstop(0.7) lcolor(black gs8 black) lpattern(solid solid dash) title(“Decision Curve Analysis Example”, size(4) color(red)) scheme(s1mono)

dca hypoglycemia prob if dataset==0, smooth xstop(0.7) lcolor(black gs8 black) lpattern(solid solid dash) title(“Decision Curve Analysis Example”, size(4) color(red)) scheme(s1mono)

dca hypoglycemia prob if dataset==1, smooth xstop(0.5) prob(no) intervention    

dca hypoglycemia prob if dataset==0, smooth xstop(0.5) prob(no) intervention  



*******************************************************************************
*******************************step3 model visualization***********************


logit hypoglycemia hyperlipidemia treat_time education hdlc ins c_peptide bun rbg fbg if dataset==1



logit hypoglycemia i.hyperlipidemia i.treat_time i.education i.hdlc i.ins i.c_peptide i.bun i.rbg i.fbg if dataset==1,or

nomolog

db nomolog

*******************************************************************************
***********************************others importance***************************
*******************************************************************************

**************************
***********NRI************

help nri

** nri outcomevar [new_marker varlist] [if] [in] [, ignoreold at(numlist) pold(varname) pnew(varname) ]

nri hypoglycemia treat_time education hdlc ins c_peptide rbg fbg if dataset==1


*意思是：低血糖是二分类Y，treat_time是新增加的变量，后面6个是old模型的变量
*可以用于预测概率与多因素比较

nri hypoglycemia treat_time education hdlc ins c_peptide rbg fbg if dataset==1,ignoreold

*意思是：单独拟合treat time的模型和拟合后面几个变量的模型之间的NRI

nri hypoglycemia treat_time education hdlc ins c_peptide rbg fbg if dataset==1, at(0.2)

*意思是：以预测概率0.2为界值，进行NRI（含treat time的7因素模型与后面6因素模型比较


nri hypoglycemia treat_time education hdlc ins c_peptide rbg fbg if dataset==1,at(0.2  0.6)

*意思是：以预测概率0.2，0.6共两个切点为界值，进行NRI（含treat time的7因素模型与后面6因素模型比较


*nri hypoglycemia,pold( pre_1 ) pnew( pre_2 )

nri hypoglycemia,pold(prob2) pnew( prob )
*意思是，直接对两个预测模型预测的P值，进行NRI分析
*咱们提示出错，是因为数据中没有pre_1和pre_2


nri hypoglycemia,at(0.2) pold( pre_1 ) pnew( pre_2 )
*意思是，直接对两个预测模型预测的P值，进行NRI分析,以0.2为界值。
nri hypoglycemia,at(0.2) pold(prob2) pnew( prob )

nri hypoglycemia,at(0.2 0.6) pold( pre_1 ) pnew( pre_2 )
*意思是，直接对两个预测模型预测的P值，进行NRI分析,以0.2、0.6为界值。
nri hypoglycemia,at(0.2 0.6) pold(prob2) pnew( prob )
***********************************
***********IDI实践*****************

help idi

*** idi outcomevar new_marker varlist [if] [in] [, relative ]
**这个idi只能算在一个模型中增加一个自变量的IDI，包括绝对和相对

**低血糖为Y，treat time为新增加的变量，后面的3个为old模型中的变量
idi hypoglycemia treat_time education hdlc ins  if dataset==1

idi hypoglycemia treat_time education hdlc ins  if dataset==1,relative


************************************************************
******如何利用别人发表文章中的Logistic回归模型
**根据别人logit模型的常数项与回归系数，计算出我们自己数据的P值
///也就是利用别人的模型和我们数据进行预测。

gen logodds_brown = 0.617*hdlc+0.272*age -0.524

gen phat =invlogit(logodds_brown)

*拿到Phat，结合结局变量Y（二分类）。就可以进行其他分析了。

roctab hypoglycemia phat
roctab hypoglycemia phat,graph
pmcalplot phat hypoglycemia
dca hypoglycemia phat

****************************************************************
***********************区分度*交叉验证*****************************  
****************************************************************

*ssc install kfoldclass

*s5模型，5重交叉验证

set seed 123
kfoldclass hypoglycemia hyperlipidemia treat_time education hdlc ins c_peptide bun rbg fbg if dataset==1, model(logit) k(5) fig

*s5模型，10重交叉验证（交叉验证都是对自己建立的最终模型做，而且就是在训练集做）

kfoldclass hypoglycemia hyperlipidemia treat_time education hdlc ins c_peptide bun rbg fbg if dataset==1, model(logit) k(10) fig

*寻找切点
*cutpt y X, youden
cutpt hypoglycemia XXXX, youden

cutpt hypoglycemia prob, youden


****************************************************************
***************************Bootstrap*****************************  
****************************************************************
help bootstrap

db bootstrap

*这是对训练集为样本，构建模型后，bootstrap法对总体数据模型的估计，主要是可信区间的变化
bootstrap, reps(50) : logit hypoglycemia hyperlipidemia treat_time education hdlc ins c_peptide bun rbg fbg if dataset==1

bootstrap,bca reps(50) : logit hypoglycemia hyperlipidemia treat_time education hdlc ins c_peptide bun rbg fbg if dataset==1

bootstrap,bca : logit hypoglycemia hyperlipidemia treat_time education hdlc ins c_peptide bun rbg fbg if dataset==1


**将bootstrap50次结果保存在一个新的文件中,取这些系数的均值，可以拿到50次抽样的方程。然后取50次的平均，就可以得到
*每个变量的系数均值以及标准差，我们可以写出这个方程，然后利用这个方程去预测概率P，有了P，就可以实现一切验证了。

bootstrap, reps(50) saving(bs): logit hypoglycemia hyperlipidemia treat_time education hdlc ins c_peptide bun rbg fbg if dataset==1

*size是指定每次抽样的样本量，默认为_N
bootstrap, reps(50) size(50) saving(bs) : logit hypoglycemia hyperlipidemia treat_time education hdlc ins c_peptide bun rbg fbg if dataset==1

******************************************************************
***************************Lassologit*****************************  
******************************************************************
*hypoglycemia.dta

*lassologit回归





lassologit hypoglycemia course_of_disease hypertension hyperlipidemia marital_status cerebrovascular_diseases treat_time history_of_hypoglycemia dn dpvd education cardiovascular gender insulin_injection_protocol drink_wine fatty_liver pnp ldlc tg hdlc alt ast cr ins c_peptide age bun ua rbg grf sbp dbp fbg hba1c tc bmi crp if dataset==1,long

lassologit hypoglycemia course_of_disease hypertension hyperlipidemia marital_status cerebrovascular_diseases treat_time history_of_hypoglycemia dn dpvd education cardiovascular gender insulin_injection_protocol drink_wine fatty_liver pnp ldlc tg hdlc alt ast cr ins c_peptide age bun ua rbg grf sbp dbp fbg hba1c tc bmi crp if dataset==1


*变量太长，可以X1-X40表示
lassologit hypoglycemia course_of_disease-crp if dataset==1,long

lassologit hypoglycemia course_of_disease-crp if dataset==1
*用最小的ebic，筛选变量，postresults必须，否则不能存储模型结果进行预测
lassologit, lic(ebic) postresults

*预测概率和线性预测值
predict double phat, pr

predict double xbhat, xb



**路径图
lassologit hypoglycemia course_of_disease hypertension hyperlipidemia marital_status cerebrovascular_diseases treat_time history_of_hypoglycemia dn dpvd education cardiovascular gender insulin_injection_protocol drink_wine fatty_liver pnp ldlc tg hdlc alt ast cr ins c_peptide age bun ua rbg grf sbp dbp fbg hba1c tc bmi crp if dataset==1, plotpath(lambda) plotlabel plotopt(legend(off))

*与上面代码含义相同
lassologit hypoglycemia course_of_disease-crp if dataset==1, plotpath(lambda) plotlabel plotopt(legend(off))



*去除标签和图例
lassologit hypoglycemia course_of_disease-crp if dataset==1, plotpath(lambda) plotopt(legend(off))

*lnlamda作图，发文常用
lassologit hypoglycemia course_of_disease-crp if dataset==1, plotpath(lnlambda) plotopt(legend(off))

*L1-norm作图，少用
lassologit hypoglycemia course_of_disease-crp if dataset==1, plotpath(norm) plotopt(legend(off))


**指定几个变量进行路径图制作
*先做lassologit
lassologit hypoglycemia course_of_disease-crp if dataset==1

*再作图选项，选择几个变量作图
lassologit,plotpath(lambda) plotvar(course_of_disease-treat_time) plotlabel plotopt(legend(off))


***交叉验证Lassologit
cvlassologit hypoglycemia course_of_disease hypertension hyperlipidemia marital_status cerebrovascular_diseases treat_time history_of_hypoglycemia dn dpvd education cardiovascular gender insulin_injection_protocol drink_wine fatty_liver pnp ldlc tg hdlc alt ast cr ins c_peptide age bun ua rbg grf sbp dbp fbg hba1c tc bmi crp if dataset==1, nfolds(5) seed(123)

*上式等价于
cvlassologit hypoglycemia course_of_disease-crp if dataset==1, nfolds(5) seed(123)

*选择lamda做模型
cvlassologit, lopt

cvlassologit, lse

*选择lamda做模型，并存储模型用于预测-预测cvlassologit的预测概率
cvlassologit, lopt postresults
predict double phat1, pr



*选择lamda做模型，并存储模型用于预测-*预测cvlassologit的预测概率
cvlassologit, lse postresults
predict double phat2, pr

**交叉验证图
cvlassologit hypoglycemia course_of_disease hypertension hyperlipidemia marital_status cerebrovascular_diseases treat_time history_of_hypoglycemia dn dpvd education cardiovascular gender insulin_injection_protocol drink_wine fatty_liver pnp ldlc tg hdlc alt ast cr ins c_peptide age bun ua rbg grf sbp dbp fbg hba1c tc bmi crp if dataset==1,nfolds(5) seed(123) plotcv
*如下与上式子相同
cvlassologit hypoglycemia course_of_disease-crp if dataset==1,nfolds(5) seed(123) plotcv


**如果想在图上加线，可以找到lopt和1se的lambda，然后图像编辑，在作图区右键，添加水平或垂直线



logit:建模-roc-auc-HL-Calibration plot-DCA-NRI-IDI-NOMO-利用别人模型-bootstrap-交叉验证-LASSO==全部搞定



*******************************************************************************
****************多重插补*****************************************************   
*******************************************************************************  
help mi

webuse mheart5                                                                                          
webuse mheart5,clear 

misstable summarize,gen(m_)

tab m_*

misstable pattern

misstable pattern,frequency

*************************************************
mi set mlong     //mlong/flong/wide

                                                                                                                                                                  
mi register imputed age bmi

set seed 29390                                                                                             

mi impute mvn age bmi = attack smokes hsgrad female, add(10)                                              

mi estimate: logistic attack smokes age bmi hsgrad female   

mi estimate,or
 
mi estimate,or : logistic attack smokes age bmi hsgrad female


*mi后，不可以直接预测概率
*logistic attack smokes age bmi hsgrad female

*predict prob,pr

*********MICE*************************
regress varlist                //设定模型为线性回归
mi set mlong       //声明数据结构，flong/mlong/wide
mi misstable summarize   //查看缺失数据

mi register imputed  age bmi hsgrad  //声明要插补的变量

mi register regular smokes female  //声明完整数据变量

mi impute chained (logit) hsgrad (regress) age bmi =smokes female,add(10)   //为不同类型缺失指定不同插补

mi estimate:logistic attack smokes age bmi hsgrad female       //多重插补Logistic回归

mi estimate,or

mi estimate, vartable nocitable   //显示插补方差信息


*******************************************************************************
****************This is the end****松哥统计************************************    
*******************************************************************************  



*采用系统自带的数据

insheet using https://archive.ics.uci.edu/ml/machine-learning-databases/spambase/spambase.data, clear comma

lassologit v58 v1-v57

lassologit, long

lassologit v58 v1-v57, lambda(40 20)

ereturn list

lassologit v58 v1-v57, lambda(40)
 
ereturn list


*To estimate the model selected by one of the information criteria, use the lic() option:
lassologit v58 v1-v57
lassologit, lic(ebic)
lassologit, lic(aicc)

*可以一行代码搞定
lassologit v58 v1-v57, lic(ebic)

*存储模型
 lassologit, lic(ebic) postresults
 
 
* Cross-validation with cvlassologit

cvlassologit v58 v1-v57, nfolds(3) seed(123)

cvlassologit, lopt

cvlassologit, lse


*展现表格
cvlassologit v58 v1-v57, nfolds(3) seed(123) tabfold


cvlassologit v58 v1-v57, nfolds(3) seed(123) tabfold stratified


cvlassologit, long

***预测

lassologit v58 v1-v57

lassologit, lic(ebic) postresults

predict double phat, pr

predict double xbhat, xb


cvlassologit v58 v1-v57
cvlassologit, lopt postresults
 predict double phat, pr

 
 
***Plotting with lassologit


 lassologit v58 v1-v57
 
 lassologit, plotpath(lambda) plotvar(v1-v5) plotlabel plotopt(legend(off))
 
 
 
***Plotting with cvlassologit

cvlassologit v58 v1-v57, nfolds(3) seed(123)

cvlassologit v58 v1-v57, plotcv





