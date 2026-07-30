//大腸直腸_Cetuximab給付規定2
library CRCCetuximabRule2 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include CRCCodeConcept version '1.0.0' called CodeConcept

include CRCReusable version '1.0.0' called Reusable
 
context Patient


//============================================
// 主要規定一：初次使用條件
//============================================


// 本次申請紀錄（以最新一筆申請作為本次申請）
define "本次申請紀錄":
  Last(
    [MedicationRequest] MR
      where MR.intent = 'plan'
        and MR.dosageInstruction[0].timing.repeat.bounds is Period
      sort by FHIRHelpers.ToDateTime((dosageInstruction[0].timing.repeat.bounds as Period).start)
  )

define "本次申請起始日期":
  FHIRHelpers.ToDateTime(("本次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).start)


/*規則1*/
//條件1
define "1規則1-1=初次使用Cetuximab與Irinotecan合併使用":
  Reusable."HasConcurrentMedicationOrder"(CodeConcept.L01FE01, CodeConcept.L01CE02)
  and Reusable."醫令類別為1"


//條件2
define "1規則1-2=用藥線別>1":
  Reusable."HasLineOfTherapyIn"({'2', '3', '4', '5'})

define "1規則1": 
  "1規則1-1=初次使用Cetuximab與Irinotecan合併使用"
  and "1規則1-2=用藥線別>1"

/*規則2*/
//條件1
define "1規則2-1=治療已接受過含5-fluorouracil、irinotecan及oxaliplatin二線以上之細胞毒性治療失敗":
  Reusable."HasPriorMedicationUse"(CodeConcept.L01FE01, CodeConcept.L01BC02)
  and Reusable."HasPriorMedicationUse"(CodeConcept.L01FE01, CodeConcept.L01XA03)
  and Reusable."HasPriorMedicationUse"(CodeConcept.L01FE01, CodeConcept.L01CE02)

//條件2
define  "1規則2-2=用於治療具表皮生長因子受體表現型(EGFR expressing)":
  exists (
    [Observation] RasObs
    where RasObs.status = 'final'
    and exists (
      RasObs.code.coding Cdg
      where Cdg.code = '69548-6'
      and Cdg in CodeConcept.LOINC
    )
    and exists (
      RasObs.component C
      where exists (
        C.code.coding Cdg
        where Cdg.code in CodeConcept.GeneTestEGFRexpressing
      )
      and C.value is not null
      and C.value is FHIR.string
      and Matches((C.value as FHIR.string).value, '(?i).*(positive|detected|present|\\+).*')
    )
  )
  
//條件3
define "1規則2-3=K-ras為原生型(wild type)":
  exists (
    [Observation] RasObs
    where RasObs.status = 'final'
    and exists (
      RasObs.code.coding Cdg
      where Cdg.code = '69548-6'
      and Cdg in CodeConcept.LOINC
    )
    and exists (
      RasObs.interpretation.coding I
      where I.code = 'NEG'
    )
  )

//條件4-1    
define "ICD代碼檢核_布林值": Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"

//條件4-2
define "1規則2-4-2=三個月內有影像檢查報告":
  Reusable."HasRecentImageReport"(CodeConcept.CetuximabRegorafenibImageReportCode, "本次申請起始日期")

//條件4-3
define "1規則2-4-3=癌症分期分數或結果為M>=1":
  Reusable."癌症分期分數或結果為M>=1"

define "1規則2-4":
  Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"
  and "1規則2-4-2=三個月內有影像檢查報告"
  and "1規則2-4-3=癌症分期分數或結果為M>=1"

define "1規則2":
  "1規則2-1=治療已接受過含5-fluorouracil、irinotecan及oxaliplatin二線以上之細胞毒性治療失敗"
  and  "1規則2-2=用於治療具表皮生長因子受體表現型(EGFR expressing)"
  and "1規則2-3=K-ras為原生型(wild type)"
  and "1規則2-4"


define "主要規定一":
  Reusable."初次申請" and
  "1規則1"
  and "1規則2"


//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

/*規則1*/
define "2規則1=提出客觀證據（如：影像學）證實無惡化，才可繼續使用":
  exists (
    [MedicationRequest] MRPlan
     where MRPlan.intent = 'plan'
     and exists (
        MRPlan.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.L01FE01
      )
  and exists (
    [DiagnosticReport] Report
     where exists (
      Report.code.coding Cdg
        where (
          Cdg in CodeConcept.ICD10PCS2023Image
          or Cdg in CodeConcept.ICD10PCS2014Image
        )
        and Cdg.code in CodeConcept.CetuximabRegorafenibImageReportCode
      )
      and Report.effective is not null
      and FHIRHelpers.ToDateTime(Report.effective) >= "本次申請起始日期" - 90 days
      and FHIRHelpers.ToDateTime(Report.effective) <= "本次申請起始日期"
      )
    )
  and Reusable."醫令類別為1"

define "主要規定二":
  Reusable."續用申請" and
  "2規則1=提出客觀證據（如：影像學）證實無惡化，才可繼續使用"


//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
//條件1
define "3規則1-1=每次申請事前審查之療程以9週為限":
  Reusable."HasMedicationPlanDurationWithin"(CodeConcept.L01FE01, 63)

//條件2
define "3規則1-2=總使用療程以18週為上限":
  Reusable."HasMedicationTotalDurationWithin"(CodeConcept.L01FE01, 126)

define "主要規定三":
  "3規則1-1=每次申請事前審查之療程以9週為限"
  and "3規則1-2=總使用療程以18週為上限"


//============================================
// 檢核結果用：必要資料存在判斷
//============================================

define "Cetuximab申請資料存在":
  Reusable."HasMedicationPlanRecord"(CodeConcept.L01FE01)

define "Irinotecan併用資料存在":
  Reusable."HasMedicationRecord"(CodeConcept.L01CE02)

define "先前細胞毒性治療資料存在":
  Reusable."HasMedicationRecord"(CodeConcept.L01BC02)
  and Reusable."HasMedicationRecord"(CodeConcept.L01CE02)
  and Reusable."HasMedicationRecord"(CodeConcept.L01XA03)

define "EGFR檢測資料存在":
  Reusable."HasObservationCode"(CodeConcept.GeneTestEGFRexpressing)

define "KRAS檢測資料存在":
  Reusable."RAS基因檢測資料存在"

define "影像檢查報告資料存在":
  Reusable."影像或檢查報告資料存在"

define "癌症分期資料存在":
  Reusable."癌症分期資料存在"

define "用藥線別資料存在":
  Reusable."用藥線別資料存在"

define "續用客觀證據資料存在":
  Reusable."影像或檢查報告資料存在"

define "療程期間資料存在":
  Reusable."HasMedicationPlanTiming"(CodeConcept.L01FE01)

define "必要資料皆存在":
  not (
    (Reusable."初次申請" and (
      not "Cetuximab申請資料存在"
      or not "Irinotecan併用資料存在"
      or not "先前細胞毒性治療資料存在"
      or not "EGFR檢測資料存在"
      or not "KRAS檢測資料存在"
      or not Reusable."主要疾病ICD診斷資料存在"
      or not "影像檢查報告資料存在"
      or not "癌症分期資料存在"
      or not "用藥線別資料存在"
    ))
    or (Reusable."續用申請" and (
      not "Cetuximab申請資料存在"
      or not "續用客觀證據資料存在"
    ))
    or not "療程期間資料存在"
  )


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and ("1規則1-1=初次使用Cetuximab與Irinotecan合併使用" or "1規則1-2=用藥線別>1" or "1規則2-1=治療已接受過含5-fluorouracil、irinotecan及oxaliplatin二線以上之細胞毒性治療失敗" or "1規則2-2=用於治療具表皮生長因子受體表現型(EGFR expressing)" or "1規則2-3=K-ras為原生型(wild type)" or "1規則2-4-2=三個月內有影像檢查報告" or "1規則2-4-3=癌症分期分數或結果為M>=1")
    then '<主要規定一：初次使用條件>\n' +
         (if "1規則1-1=初次使用Cetuximab與Irinotecan合併使用" 
           then '● 規則1-1：Cetuximab與Irinotecan合併使用（參考資訊）\n' else '') +
         (if "1規則1-2=用藥線別>1" 
           then '● 規則1-2：用藥線別為二線以上\n' else '') +
         (if "1規則2-1=治療已接受過含5-fluorouracil、irinotecan及oxaliplatin二線以上之細胞毒性治療失敗" 
           then '● 規則2-1：已接受過含5-fluorouracil、irinotecan及oxaliplatin二線以上之細胞毒性治療失敗\n' else '') +
         (if "1規則2-2=用於治療具表皮生長因子受體表現型(EGFR expressing)" 
           then '● 規則2-2：用於治療具表皮生長因子受體表現型（EGFR expressing）\n' else '') +
         (if "1規則2-3=K-ras為原生型(wild type)" 
           then '● 規則2-3：K-ras為原生型（wild type）\n' else '') +
         (if Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" 
           then '● 規則2-4-1：主要疾病之ICD代碼為C18、C19、C20、C21\n' else '') +
         (if "1規則2-4-2=三個月內有影像檢查報告"
           then '● 規則2-4-2：三個月內有影像檢查報告\n' else '') +
         (if "1規則2-4-3=癌症分期分數或結果為M>=1" 
           then '● 規則2-4-3：癌症分期為轉移性（M≥1）\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定二：續用條件
  (if Reusable."續用申請" and "2規則1=提出客觀證據（如：影像學）證實無惡化，才可繼續使用" 
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '● 續用規則1：提出客觀證據（如：影像學）證實無惡化\n' +
         '\n'  
    else '') +
  
  // 主要規定三：藥品使用規則
  (if "3規則1-1=每次申請事前審查之療程以9週為限" or "3規則1-2=總使用療程以18週為上限"
    then '<主要規定三：藥品使用規則>\n' +
         (if "3規則1-1=每次申請事前審查之療程以9週為限" 
           then '● 規則3-1：每次申請事前審查之療程以9週為限（參考資訊）\n' else '') +
         (if "3規則1-2=總使用療程以18週為上限" 
           then '● 規則3-2：總使用療程以18週為上限（參考資訊）\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 條件或代碼不符合
//============================================

define function "不符合項目_條件或代碼不符合"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if Reusable."初次申請" and (
    ("Irinotecan併用資料存在" and not "1規則1-1=初次使用Cetuximab與Irinotecan合併使用")
    or ("用藥線別資料存在" and not "1規則1-2=用藥線別>1")
    or ("先前細胞毒性治療資料存在" and not "1規則2-1=治療已接受過含5-fluorouracil、irinotecan及oxaliplatin二線以上之細胞毒性治療失敗")
    or ("EGFR檢測資料存在" and not "1規則2-2=用於治療具表皮生長因子受體表現型(EGFR expressing)")
    or ("KRAS檢測資料存在" and not "1規則2-3=K-ras為原生型(wild type)")
    or (Reusable."主要疾病ICD診斷資料存在" and not Reusable."主要疾病之ICD-10使用C18、C19、C20、C21")
    or ("影像檢查報告資料存在" and not "1規則2-4-2=三個月內有影像檢查報告")
    or ("癌症分期資料存在" and not "1規則2-4-3=癌症分期分數或結果為M>=1")
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "Irinotecan併用資料存在" and not "1規則1-1=初次使用Cetuximab與Irinotecan合併使用"
           then '▲ 規則1-1：未符合Cetuximab與Irinotecan併用條件（參考資訊）\n' else '') +
         (if "用藥線別資料存在" and not "1規則1-2=用藥線別>1" 
           then '▲ 規則1-2：用藥線別不為二線以上\n' else '') +
         (if "先前細胞毒性治療資料存在" and not "1規則2-1=治療已接受過含5-fluorouracil、irinotecan及oxaliplatin二線以上之細胞毒性治療失敗"
           then '▲ 規則2-1：先前細胞毒性治療資料未完整符合條件\n' else '') +
         (if "EGFR檢測資料存在" and not "1規則2-2=用於治療具表皮生長因子受體表現型(EGFR expressing)"
           then '▲ 規則2-2：EGFR expressing檢測結果不符合\n' else '') +
         (if "KRAS檢測資料存在" and not "1規則2-3=K-ras為原生型(wild type)" 
           then '▲ 規則2-3：K-ras檢測結果不符合原生型（wild type）\n' else '') +
         (if Reusable."主要疾病ICD診斷資料存在" and not Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" 
           then '▲ 規則2-4-1：主要疾病之ICD代碼未使用C18、C19、C20、C21\n' else '') +
         (if "影像檢查報告資料存在" and not "1規則2-4-2=三個月內有影像檢查報告"
           then '▲ 規則2-4-2：影像檢查報告不在三個月內或代碼不符合\n' else '') +
         (if "癌症分期資料存在" and not "1規則2-4-3=癌症分期分數或結果為M>=1" 
           then '▲ 規則2-4-3：癌症分期分數或結果不為M≥1\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定三：藥品使用規則 - 代碼條件不符
  (if "療程期間資料存在" and (not "3規則1-1=每次申請事前審查之療程以9週為限" or not "3規則1-2=總使用療程以18週為上限")
    then '<主要規定三：藥品使用規則>\n' +
         (if "療程期間資料存在" and not "3規則1-1=每次申請事前審查之療程以9週為限" 
           then '▲ 規則3-1：每次申請事前審查之療程超過9週上限（參考資訊）\n' else '') +
         (if "療程期間資料存在" and not "3規則1-2=總使用療程以18週為上限" 
           then '▲ 規則3-2：總使用療程超過18週上限（參考資訊）\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
    not "Cetuximab申請資料存在"
    or not "Irinotecan併用資料存在"
    or not "先前細胞毒性治療資料存在"
    or not "EGFR檢測資料存在"
    or not "KRAS檢測資料存在"
    or not Reusable."主要疾病ICD診斷資料存在"
    or not "影像檢查報告資料存在"
    or not "癌症分期資料存在"
    or not "用藥線別資料存在"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "Cetuximab申請資料存在" then '▲ 申請醫令：未提供Cetuximab申請醫令資料\n' else '') +
         (if not "Irinotecan併用資料存在"
           then '▲ 規則1-1：未提供Irinotecan處方（參考資訊）\n' else '') +
         (if not "先前細胞毒性治療資料存在"
           then '▲ 規則2-1：未提供含5-fluorouracil、irinotecan及oxaliplatin二線以上之細胞毒性治療失敗的歷史用藥資料\n' else '') +
         (if not "EGFR檢測資料存在"
           then '▲ 規則2-2：未提供EGFR expressing檢測結果\n' else '') +
         (if not "KRAS檢測資料存在" then '▲ 規則2-3：未提供K-ras檢測資料\n' else '') +
         (if not Reusable."主要疾病ICD診斷資料存在" then '▲ 規則2-4-1：未提供主要疾病ICD診斷資料\n' else '') +
         (if not "影像檢查報告資料存在"
           then '▲ 規則2-4-2：未提供三個月內影像檢查報告\n' else '') +
         (if not "癌症分期資料存在" then '▲ 規則2-4-3：未提供癌症分期分數或結果資料\n' else '') +
         (if not "用藥線別資料存在" then '▲ 規則1-2：未提供用藥線別資料\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (not "Cetuximab申請資料存在" or not "續用客觀證據資料存在")
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if not "Cetuximab申請資料存在" then '▲ 申請醫令：未提供Cetuximab申請醫令資料\n' else '') +
         (if not "續用客觀證據資料存在" then '▲ 續用規則1：未提供客觀證據（如：影像學）\n' else '') +
         '\n'  
    else '') +

  (if not "療程期間資料存在"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則3-1/3-2：未提供療程起迄日期資料（參考資訊）\n' +
         '\n'
    else '')

//============================================
// 審核結果
//============================================

define "大腸直腸癌Cetuximab二線以上治療申請結果_布林":
  case
    when Reusable."初次申請" then (
      "1規則1-2=用藥線別>1" and
      "1規則2"
    )
    when Reusable."續用申請" then (
      "2規則1=提出客觀證據（如：影像學）證實無惡化，才可繼續使用"
    )
    else false
  end

define "大腸直腸癌Cetuximab二線以上治療申請結果":
  if (
    Reusable."初次申請" and 
    "1規則1-2=用藥線別>1" and
    "1規則2"
  )
  then '✓通過：初次使用－大腸直腸癌 Cetuximab 第二線用藥申請'
  else if (
    Reusable."續用申請" and
    "2規則1=提出客觀證據（如：影像學）證實無惡化，才可繼續使用"
  )
  then '✓通過：續用－大腸直腸癌 Cetuximab 第二線用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－大腸直腸癌 Cetuximab 第二線用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－大腸直腸癌 Cetuximab 第二線用藥申請'
  else '✖不通過：無法判定申請類型－大腸直腸癌 Cetuximab 第二線用藥申請'


//============================================
// 審核報告總結
//============================================

define "報告總結":
  '\n=== 大腸直腸癌之Cetuximab(二線治療) 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "大腸直腸癌Cetuximab二線以上治療申請結果" +
  '\n===============================================\n'
