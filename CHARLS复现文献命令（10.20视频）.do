
use "D:\Desktop\CHARLS数据库 - 副本\Harmonized CHARLS\常规波versionD\H_CHARLS_D_Data\H_CHARLS_D_Data.dta"
keep if !missing(h1rural, h2rural, h3rural, h4rural)

* 重命名hXrural系列变量
forvalues i = 1/4 {
    rename h`i'rural rural`i'
}

* 定义慢性疾病变量前缀列表
local diseases "hibpe diabe cancre lunge hearte stroke psyche arthre dyslipe livere kidneye digeste asthmae"

* 循环重命名各波慢性疾病变量
foreach disease in `diseases' {
    forvalues i = 1/4 {
        rename r`i'`disease' D`disease'`i'
    }
}

* 删除可能已存在的标签
capture label drop agecat

* 为每个波次创建年龄分类变量
foreach wave in 1 2 3 4 {
    * 创建年龄分类变量
    gen agecat`wave' = .
    replace agecat`wave' = 1 if r`wave'agey >= 45 & r`wave'agey <= 59
    replace agecat`wave' = 2 if r`wave'agey >= 60 & r`wave'agey <= 74
    replace agecat`wave' = 3 if r`wave'agey >= 75 & r`wave'agey != .
    
    * 添加变量标签
    label variable agecat`wave' "Wave `wave' Age Category"
}

* 定义标签并应用到所有变量
label define agecat 1 "45-59" 2 "60-74" 3 "75+"
foreach wave in 1 2 3 4 {
    label values agecat`wave' agecat
}

* 为四个波次创建三分类教育变量
forvalues wave = 1/4 {
    * 创建三分类教育变量
    gen edu_cat`wave' = .
    
    * Elementary School (小学及以下): 原始分类1-4
    replace edu_cat`wave' = 1 if inlist(raeduc_c, 1, 2, 3, 4)
    
    * Secondary School (中学): 原始分类5-7
    replace edu_cat`wave' = 2 if inlist(raeduc_c, 5, 6, 7)
    
    * University (大学及以上): 原始分类8-10
    replace edu_cat`wave' = 3 if inlist(raeduc_c, 8, 9, 10)
    
    * 添加变量标签
    label variable edu_cat`wave' "Wave `wave' Education Category"
}

* 定义值标签并应用到所有变量
label define edu_cat 1 "Elementary School" 2 "Secondary School" 3 "University"
forvalues wave = 1/4 {
    label values edu_cat`wave' edu_cat
}

* 验证结果
forvalues wave = 1/4 {
    tab edu_cat`wave'
}

gen gender1= ragender
gen gender2= ragender
gen gender3= ragender
gen gender4= ragender

* 删除可能已存在的标签
capture label drop marital_cat

* 为四个波次创建二分类婚姻状况变量
forvalues wave = 1/4 {
    * 创建二分类婚姻状况变量
    gen marital_cat`wave' = .
    
    * Married: 包括married和partnered
    replace marital_cat`wave' = 1 if inlist(r`wave'mstat, 1, 3)
    
    * Single: 包括separated, divorced, widowed, never married
    replace marital_cat`wave' = 0 if inlist(r`wave'mstat, 4, 5, 7, 8)
    
    * 添加变量标签
    label variable marital_cat`wave' "Wave `wave' Marital Status"
}

* 定义值标签并应用到所有变量
label define marital_cat 1 "Married" 0 "Single"
forvalues wave = 1/4 {
    label values marital_cat`wave' marital_cat
}

* 验证结果
forvalues wave = 1/4 {
    tab marital_cat`wave'
}

order  agecat1 agecat2 agecat3 agecat4 gender1 gender2 gender3 gender4 h1rural h2rural h3rural h4rural edu_cat1 edu_cat2 edu_cat3 edu_cat4 marital_cat1 marital_cat2 marital_cat3 marital_cat4 



* 为前四波生成慢性病变量和共病变量
forvalues wave = 1/4 {
    * 处理缺失值
    foreach var in r`wave'hibpe r`wave'diabe r`wave'cancre r`wave'lunge r`wave'hearte r`wave'stroke r`wave'psyche r`wave'arthre r`wave'dyslipe r`wave'livere r`wave'kidneye r`wave'digeste r`wave'asthmae {
        replace `var' = . if inlist(`var', .d, .r, .m)
    }
    
    * 生成慢性病变量
    gen Chronic_Disease`wave' = 0
    foreach var in r`wave'hibpe r`wave'diabe r`wave'cancre r`wave'lunge r`wave'hearte r`wave'stroke r`wave'psyche r`wave'arthre r`wave'dyslipe r`wave'livere r`wave'kidneye r`wave'digeste r`wave'asthmae {
        replace Chronic_Disease`wave' = 1 if `var' == 1
        replace Chronic_Disease`wave' = . if missing(`var')
    }
    
    * 生成共病变量
    gen disease_count`wave' = 0
    foreach var in r`wave'hibpe r`wave'diabe r`wave'cancre r`wave'lunge r`wave'hearte r`wave'stroke r`wave'psyche r`wave'arthre r`wave'dyslipe r`wave'livere r`wave'kidneye r`wave'digeste r`wave'asthmae {
        replace disease_count`wave' = disease_count`wave' + 1 if `var' == 1
    }
    
    gen Comorbidity`wave' = (disease_count`wave' >= 2) if !missing(disease_count`wave')
    replace Comorbidity`wave' = . if missing(Chronic_Disease`wave')
    
    * 删除临时计数变量
    drop disease_count`wave'
}
* 删除可能已存在的标签
capture label drop edu_cat

* 处理IADL变量的缺失值，将.d, .r, .m转换为标准缺失值(.)

* Wave 1 IADL变量
foreach var in r1moneya r1medsa r1shopa r1mealsa r1housewka {
    recode `var' (.d .r .m = .)
}

* Wave 2 IADL变量
foreach var in r2moneya r2medsa r2shopa r2mealsa r2housewka r2phonea {
    recode `var' (.d .r .m = .)
}

* Wave 3 IADL变量
foreach var in r3moneya r3medsa r3shopa r3mealsa r3housewka r3phonea {
    recode `var' (.d .r .m = .)
}

* Wave 4 IADL变量
foreach var in r4moneya r4medsa r4shopa r4mealsa r4housewka r4phonea {
    recode `var' (.d .r .m = .)
}

* 创建二分类IADL变量（Normal=0, Impaired=1）

* Wave 1: 只有5个IADL项目
gen iadl_impaired1 = 0
foreach var in r1moneya r1medsa r1shopa r1mealsa r1housewka {
    replace iadl_impaired1 = 1 if `var' == 1
}
replace iadl_impaired1 = . if missing(r1moneya, r1medsa, r1shopa, r1mealsa, r1housewka)
label variable iadl_impaired1 "Wave 1 IADL Status"
label define iadl_status 0 "Normal" 1 "Impaired"
label values iadl_impaired1 iadl_status

* Wave 2: 有6个IADL项目
gen iadl_impaired2 = 0
foreach var in r2moneya r2medsa r2shopa r2mealsa r2housewka r2phonea {
    replace iadl_impaired2 = 1 if `var' == 1
}
replace iadl_impaired2 = . if missing(r2moneya, r2medsa, r2shopa, r2mealsa, r2housewka, r2phonea)
label variable iadl_impaired2 "Wave 2 IADL Status"
label values iadl_impaired2 iadl_status

* Wave 3: 有6个IADL项目
gen iadl_impaired3 = 0
foreach var in r3moneya r3medsa r3shopa r3mealsa r3housewka r3phonea {
    replace iadl_impaired3 = 1 if `var' == 1
}
replace iadl_impaired3 = . if missing(r3moneya, r3medsa, r3shopa, r3mealsa, r3housewka, r3phonea)
label variable iadl_impaired3 "Wave 3 IADL Status"
label values iadl_impaired3 iadl_status

* Wave 4: 有6个IADL项目
gen iadl_impaired4 = 0
foreach var in r4moneya r4medsa r4shopa r4mealsa r4housewka r4phonea {
    replace iadl_impaired4 = 1 if `var' == 1
}
replace iadl_impaired4 = . if missing(r4moneya, r4medsa, r4shopa, r4mealsa, r4housewka, r4phonea)
label variable iadl_impaired4 "Wave 4 IADL Status"
label values iadl_impaired4 iadl_status

* 验证结果
forvalues wave = 1/4 {
    tab iadl_impaired`wave'
}

* 处理ADL变量的缺失值，将.d, .r, .m转换为标准缺失值(.)
forvalues wave = 1/4 {
    foreach var in r`wave'dressa r`wave'batha r`wave'eata r`wave'beda r`wave'toilta r`wave'urina {
        recode `var' (.d .r .m = .)
    }
}

* 删除可能已存在的标签
capture label drop adl_status

* 创建二分类ADL变量（Normal=0, Impaired=1）
forvalues wave = 1/4 {
    gen adl_impaired`wave' = 0
    foreach var in r`wave'dressa r`wave'batha r`wave'eata r`wave'beda r`wave'toilta r`wave'urina {
        replace adl_impaired`wave' = 1 if `var' == 1
    }
    replace adl_impaired`wave' = . if missing(r`wave'dressa, r`wave'batha, r`wave'eata, r`wave'beda, r`wave'toilta, r`wave'urina)
    label variable adl_impaired`wave' "Wave `wave' ADL Status"
}

* 定义值标签并应用到所有变量
label define adl_status 0 "Normal" 1 "Impaired"
forvalues wave = 1/4 {
    label values adl_impaired`wave' adl_status
}

* 验证结果
forvalues wave = 1/4 {
    tab adl_impaired`wave'
}

* 处理门诊就诊变量的缺失值，将.d, .r, .m转换为标准缺失值(.)
forvalues wave = 1/4 {
    recode r`wave'doctor1m (.d .r .m = .)
}

* 删除可能已存在的标签
capture label drop outpatient

* 创建二分类门诊就诊变量（No=0, Yes=1）
forvalues wave = 1/4 {
    gen outpatient`wave' = r`wave'doctor1m
    replace outpatient`wave' = . if missing(r`wave'doctor1m)
    label variable outpatient`wave' "Wave `wave' Outpatient Visit Last Month"
}

* 定义值标签并应用到所有变量
label define outpatient 0 "No" 1 "Yes"
forvalues wave = 1/4 {
    label values outpatient`wave' outpatient
}

* 验证结果
forvalues wave = 1/4 {
    tab outpatient`wave'
}

* 处理四个波次子女联系变量的缺失值，并创建二分类变量

* 删除可能已存在的标签
capture label drop contact

* 定义值标签
label define contact 0 "No" 1 "Yes"

* 处理面对面接触变量
forvalues wave = 1/4 {
    * 处理缺失值
    recode h`wave'kcntf (.d .r .m .k = .)
    
    * 创建二分类变量
    gen face_contact`wave' = h`wave'kcntf
    replace face_contact`wave' = . if missing(h`wave'kcntf)
    label variable face_contact`wave' "Wave `wave' Face-to-face contact with children weekly"
    label values face_contact`wave' contact
}

* 处理电话/邮件联系变量
forvalues wave = 1/4 {
    * 处理缺失值
    recode h`wave'kcntpm (.d .r .m .k .s = .)
    
    * 创建二分类变量
    gen phone_contact`wave' = h`wave'kcntpm
    replace phone_contact`wave' = . if missing(h`wave'kcntpm)
    label variable phone_contact`wave' "Wave `wave' Phone/email contact with children weekly"
    label values phone_contact`wave' contact
}

* 处理任何形式联系变量
forvalues wave = 1/4 {
    * 处理缺失值
    recode h`wave'kcnt (.d .r .m .k = .)
    
    * 创建二分类变量
    gen any_contact`wave' = h`wave'kcnt
    replace any_contact`wave' = . if missing(h`wave'kcnt)
    label variable any_contact`wave' "Wave `wave' Any contact with children weekly"
    label values any_contact`wave' contact
}

* 验证结果
forvalues wave = 1/4 {
    tab face_contact`wave'
    tab phone_contact`wave'
    tab any_contact`wave'
}

* 处理四个波次社会参与变量的缺失值，并创建二分类变量

* 删除可能已存在的标签
capture label drop social_act

* 定义值标签
label define social_act 0 "No" 1 "Yes"

* 处理社会参与变量
forvalues wave = 1/4 {
    * 处理缺失值 - 将.d, .r, .m, .p转换为标准缺失值(.)
    recode r`wave'socwk (.d .r .m .p = .)
    
    * 创建二分类变量
    gen social_activity`wave' = r`wave'socwk
    replace social_activity`wave' = . if missing(r`wave'socwk)
    label variable social_activity`wave' "Wave `wave' Participate in social activities"
    label values social_activity`wave' social_act
}

* 验证结果
forvalues wave = 1/4 {
    tab social_activity`wave'
}

* 处理四个波次运动活动变量的缺失值，并创建二分类变量

* 删除可能已存在的标签
capture label drop activity

* 定义值标签
label define activity 0 "No" 1 "Yes"

* 处理高强度运动变量
forvalues wave = 1/4 {
    * 处理缺失值 - 将.m, .r转换为标准缺失值(.)
    recode r`wave'vgact_c (.m .r = .)
    
    * 创建二分类变量
    gen vigorous_activity`wave' = r`wave'vgact_c
    replace vigorous_activity`wave' = . if missing(r`wave'vgact_c)
    label variable vigorous_activity`wave' "Wave `wave' Vigorous physical activity"
    label values vigorous_activity`wave' activity
}

* 处理中等强度运动变量
forvalues wave = 1/4 {
    * 处理缺失值 - 将.m, .r转换为标准缺失值(.)
    recode r`wave'mdact_c (.m .r = .)
    
    * 创建二分类变量
    gen moderate_activity`wave' = r`wave'mdact_c
    replace moderate_activity`wave' = . if missing(r`wave'mdact_c)
    label variable moderate_activity`wave' "Wave `wave' Moderate physical activity"
    label values moderate_activity`wave' activity
}

* 处理低强度运动变量
forvalues wave = 1/4 {
    * 处理缺失值 - 将.m, .r转换为标准缺失值(.)
    recode r`wave'ltact_c (.m .r = .)
    
    * 创建二分类变量
    gen light_activity`wave' = r`wave'ltact_c
    replace light_activity`wave' = . if missing(r`wave'ltact_c)
    label variable light_activity`wave' "Wave `wave' Light physical activity"
    label values light_activity`wave' activity
}

* 验证结果
forvalues wave = 1/4 {
    tab vigorous_activity`wave'
    tab moderate_activity`wave'
    tab light_activity`wave'
}

* 处理四个波次吸烟变量缺失值并创建三分类吸烟状态变量

* 删除可能已存在的标签
capture label drop smoking_status

* 定义三分类值标签
label define smoking_status 1 "Never smoker" 2 "Former smoker" 3 "Current smoker"

* 处理吸烟变量并创建三分类变量
forvalues wave = 1/4 {
    * 处理缺失值
    recode r`wave'smokev (.d .r .m = .)
    recode r`wave'smoken (.m = .)
    
    * 创建三分类吸烟状态变量
    gen smoking_status`wave' = .
    
    * 从不吸烟: 从未吸烟(r`wave'smokev = 0)
    replace smoking_status`wave' = 1 if r`wave'smokev == 0
    
    * 曾经吸烟: 曾经吸烟但现在不吸(r`wave'smokev = 1 & r`wave'smoken = 0)
    replace smoking_status`wave' = 2 if r`wave'smokev == 1 & r`wave'smoken == 0
    
    * 当前吸烟: 现在吸烟(r`wave'smoken = 1)
    replace smoking_status`wave' = 3 if r`wave'smoken == 1
    
    * 如果任一变量缺失，则设为缺失
    replace smoking_status`wave' = . if missing(r`wave'smokev) | missing(r`wave'smoken)
    
    * 添加变量标签
    label variable smoking_status`wave' "Wave `wave' Smoking Status"
    label values smoking_status`wave' smoking_status
}

* 验证结果
forvalues wave = 1/4 {
    tab smoking_status`wave'
}

* 处理四个波次饮酒变量缺失值并创建三分类饮酒状态变量

* 删除可能已存在的标签
capture label drop drinking_status

* 定义三分类值标签
label define drinking_status 1 "Never drinker" 2 "Former drinker" 3 "Current drinker"

* 处理饮酒变量并创建三分类变量
forvalues wave = 1/4 {
    * 处理缺失值
    recode r`wave'drinkev (.d .r .m = .)
    recode r`wave'drinkl (.d .r .m = .)
    
    * 创建三分类饮酒状态变量
    gen drinking_status`wave' = .
    
    * 从不饮酒: 从未饮酒(r`wave'drinkev = 0)
    replace drinking_status`wave' = 1 if r`wave'drinkev == 0
    
    * 曾经饮酒: 曾经饮酒但去年不饮(r`wave'drinkev = 1 & r`wave'drinkl = 0)
    replace drinking_status`wave' = 2 if r`wave'drinkev == 1 & r`wave'drinkl == 0
    
    * 当前饮酒: 去年饮酒(r`wave'drinkl = 1)
    replace drinking_status`wave' = 3 if r`wave'drinkl == 1
    
    * 如果任一变量缺失，则设为缺失
    replace drinking_status`wave' = . if missing(r`wave'drinkev) | missing(r`wave'drinkl)
    
    * 添加变量标签
    label variable drinking_status`wave' "Wave `wave' Drinking Status"
    label values drinking_status`wave' drinking_status
}

* 验证结果
forvalues wave = 1/4 {
    tab drinking_status`wave'
}全部代码修改 分类变量要生数值型不要字符串 类别对应数值

* 处理四个波次CESD-10抑郁量表变量的缺失值
forvalues wave = 1/4 {
    recode r`wave'cesd10 (.d .r .m = .)
}

* 删除可能已存在的标签
capture label drop depression

* 创建二分类抑郁风险变量 (CESD-10 > 10 表示有抑郁风险)
forvalues wave = 1/4 {
    gen depression_risk`wave' = (r`wave'cesd10 > 10) if !missing(r`wave'cesd10)
    replace depression_risk`wave' = . if missing(r`wave'cesd10)
    label variable depression_risk`wave' "Wave `wave' Depression Risk (CESD-10 > 10)"
}

* 定义值标签并应用到所有变量
label define depression 0 "No risk" 1 "At risk"
forvalues wave = 1/4 {
    label values depression_risk`wave' depression
}

* 验证结果
forvalues wave = 1/4 {
    tab depression_risk`wave'
    summarize r`wave'cesd10
}

order agecat1 agecat2 agecat3 agecat4 gender1 gender2 gender3 gender4 h1rural h2rural h3rural h4rural edu_cat1 edu_cat2 edu_cat3 edu_cat4 marital_cat1 marital_cat2 marital_cat3 marital_cat4 r1hibpe r2hibpe r3hibpe r4hibpe r1diabe r2diabe r3diabe r4diabe r1cancre r2cancre r3cancre r4cancre r1lunge r2lunge r3lunge r4lunge r1hearte r2hearte r3hearte r4hearte r1stroke r2stroke r3stroke r4stroke r1psyche r3psyche r4psyche r1arthre r2arthre r3arthre r4arthre r1dyslipe r2dyslipe r3dyslipe r4dyslipe r1livere r2livere r3livere r1kidneye r2kidneye r3kidneye r4kidneye r1digeste r2digeste r4digeste r2asthmae r3asthmae r4asthmae Chronic_Disease1 Chronic_Disease2 Chronic_Disease3 Chronic_Disease4 Comorbidity1 Comorbidity3 Comorbidity4 iadl_impaired1 iadl_impaired2 iadl_impaired3 iadl_impaired4 adl_impaired1 adl_impaired2 adl_impaired4 outpatient1 outpatient2 outpatient4 face_contact1 face_contact2 face_contact3 phone_contact1 phone_contact2 phone_contact3 phone_contact4 any_contact2 any_contact3 social_activity1 social_activity2 social_activity3 vigorous_activity1 vigorous_activity2 vigorous_activity3 vigorous_activity4 moderate_activity1 moderate_activity3 moderate_activity4 light_activity1 light_activity2 light_activity3 light_activity4 smoking_status1 smoking_status2 smoking_status3 drinking_status1 drinking_status2 drinking_status3 drinking_status4


























