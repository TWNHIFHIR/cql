//大腸直腸_Cetuximab給付規定2
library CRCCetuximabRule2 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include CRCCodeConcept version '1.0.0' called CodeConcept

include CRCReusable version '1.0.0' called Reusable
 
context Patient

//============================================
// 申請類型判斷
//============================================

define "初次申請":
  "申請類型" = '初次使用'

define "續用申請":
  "申請類型" = '續用'

define "申請類型未知":
  "申請類型" = '無法判斷申請類型'

define "申請類型":
  case
    when Reusable."續用註記為1" then '初次使用'
    when Reusable."續用註記為2" then '續用'
    else '無法判斷申請類型'
  end


//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/
//條件1
define "規則1-1=初次使用Cetuximab與Irinotecan合併使用":
(
  // Cetuximab 申請（作為基準時間）
  exists (
    [MedicationRequest] MRPlan
    where MRPlan.intent = 'plan'
    and exists (
      MRPlan.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
      and Cdg.code in CodeConcept.L01FE01
    )
    and MRPlan.dosageInstruction[0].timing.repeat.bounds is Period
    and (start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
    and (end of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period)) is not null

    // 存在 Irinotecan 處方且藥物處方的起始及終止日期涵蓋在事前審查藥品申請日期使用的區間內
    and exists (
      [MedicationRequest] MROrder2
      where MROrder2.intent = 'order'
      and exists (
        MROrder2.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.L01CE02
      )
      and Reusable."HasValidTiming"(MROrder2)
      and MROrder2.dosageInstruction[0].timing.repeat.bounds is Period
      and (start of (MROrder2.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
      and (end of (MROrder2.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
      and (start of (MROrder2.dosageInstruction[0].timing.repeat.bounds as Period))
          <= (end of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period))
      and (end of (MROrder2.dosageInstruction[0].timing.repeat.bounds as Period))
          >= (start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period))
    )
  )
)
and Reusable."醫令類別為1"


//條件2
define "規則1-2=用藥線別>1":
  exists (
    [Claim] C
      where exists (
        C.item I
          where exists (
            I.modifier M
              where exists (
                M.coding Cdg
                  where Cdg in CodeConcept.NHILOT
                    and Cdg.code in {'2', '3', '4', '5'}
              )
          )
      )
  )

define "規則1": 
  "規則1-1=初次使用Cetuximab與Irinotecan合併使用"
  and "規則1-2=用藥線別>1"

/*規則2*/
//條件1
define "規則2-1=治療已接受過含5-fluorouracil、irinotecan及oxaliplatin二線以上之細胞毒性治療失敗":
  exists (
    [MedicationRequest] CurrentCetuximab
    where CurrentCetuximab.intent = 'plan'
    and exists (
      CurrentCetuximab.medication.coding CetuximabCoding
      where CetuximabCoding in CodeConcept.NHIMedication
      and CetuximabCoding.code in CodeConcept.L01FE01
    )
    and Reusable."HasValidTiming"(CurrentCetuximab)

    // 存在 Fluorouracil 處方，且結束時間早於本次申請
    and exists (
      [MedicationRequest] MROrder1
      where MROrder1.intent = 'order'
      and exists (
        MROrder1.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and (
          Cdg.code in CodeConcept.L01BC02
          or Cdg.code in CodeConcept.L01CE02
        )
      )
      and Reusable."HasValidTiming"(MROrder1)
      and Reusable."GetEndTime"(MROrder1) <= Reusable."GetStartTime"(CurrentCetuximab)
    )

    // 存在 Oxaliplatin 處方，且結束時間早於本次申請
    and exists (
      [MedicationRequest] MROrder2
      where MROrder2.intent = 'order'
      and exists (
        MROrder2.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.L01XA03
      )
      and Reusable."HasValidTiming"(MROrder2)
      and Reusable."GetEndTime"(MROrder2) <= Reusable."GetStartTime"(CurrentCetuximab)
    )

    // 存在 Irinotecan 處方，且結束時間早於本次申請
    and exists (
      [MedicationRequest] MROrder3
      where MROrder3.intent = 'order'
      and exists (
        MROrder3.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.L01CE02
      )
      and Reusable."HasValidTiming"(MROrder3)
      and Reusable."GetEndTime"(MROrder3) <= Reusable."GetStartTime"(CurrentCetuximab)
    )
  )

//條件2
define  "規則2-2=用於治療具表皮生長因子受體表現型(EGFR expressing)":
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
      and Matches((C.value as FHIR.string).value, '(?i).*(positive|detected|present|expressed|overexpressed|amplified|\\+).*')
    )
  )

//條件3
define "規則2-3=K-ras為原生型(wild type)":
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
        where Cdg.code in CodeConcept.GeneTest
      )
    )
    and exists (
      RasObs.interpretation.coding I
      where I.code = 'NEG'
    )
  )

//條件4-1    
define "ICD代碼檢核_布林值": Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"

//條件4-2
define "規則2-4-2=三個月內有影像檢查報告":
  exists (
    [DiagnosticReport] O
    where exists (
      O.code.coding Cdg
      where (
        Cdg in CodeConcept.ICD10PCS2023Image
        or Cdg in CodeConcept.ICD10PCS2014Image
      )
      and Cdg.code in CodeConcept.CetuximabRegorafenibImageReportCode
    )
    and O.effective is not null
    and FHIRHelpers.ToDateTime(O.effective) >= Today() - 90 days
    and FHIRHelpers.ToDateTime(O.effective) <= Today()
  )

//條件4-3
define "規則2-4-3=癌症分期分數或結果為M>=1":
  Count(
    [Observation] O
    where exists (
      O.code.coding Cdg
      where Cdg.code = '399390009'
        and Cdg in CodeConcept.SNOMED
    )
    and O.value is not null
    and O.value is FHIR.string
    and Matches((O.value as FHIR.string).value, '.*M[1-9].*')
  ) > 0

define "規則2-4":
  Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"
  and "規則2-4-2=三個月內有影像檢查報告"
  and "規則2-4-3=癌症分期分數或結果為M>=1"

define "規則2":
  "規則2-1=治療已接受過含5-fluorouracil、irinotecan及oxaliplatin二線以上之細胞毒性治療失敗"
  and  "規則2-2=用於治療具表皮生長因子受體表現型(EGFR expressing)"
  and "規則2-3=K-ras為原生型(wild type)"
  and "規則2-4"


define "主要規定一":
  "初次申請" and
  "規則1"
  and "規則2"


//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

/*規則1*/
define "規則1=提出客觀證據（如：影像學）證實無惡化，才可繼續使用":
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
      and FHIRHelpers.ToDateTime(Report.effective) >= Today() - 90 days
      and FHIRHelpers.ToDateTime(Report.effective) <= Today()
      )
    )
  and Reusable."醫令類別為1"

define "主要規定二":
  "續用申請" and
  "規則1=提出客觀證據（如：影像學）證實無惡化，才可繼續使用"


//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
//條件1
define "規則1-1=每次申請事前審查之療程以9週為限":
  exists [MedicationRequest] MRPlan
  where MRPlan.intent = 'plan'
  and exists (
  MRPlan.medication.coding Cdg
  where Cdg in CodeConcept.NHIMedication
  and Cdg.code in CodeConcept.L01FE01
   )
  and days between
  start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period)
  and
  end of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period)
  <= 63

//條件2
define "規則1-2=總使用療程以18週為上限":
  Sum(
   [MedicationRequest] MRTotal
  where (MRTotal.intent = 'plan' or MRTotal.intent = 'order')
  and (MRTotal.status is null or MRTotal.status in { 'active', 'completed', 'on-hold' })
  and exists MRTotal.dosageInstruction
  and MRTotal.dosageInstruction[0].timing.repeat.bounds is Period
  and (start of (MRTotal.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
  and (end of (MRTotal.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
  and exists (
  MRTotal.medication.coding Cdg
  where Cdg in CodeConcept.NHIMedication
  and Cdg.code in CodeConcept.L01FE01
   )
  return
  days between
  start of (MRTotal.dosageInstruction[0].timing.repeat.bounds as Period)
  and
  end of (MRTotal.dosageInstruction[0].timing.repeat.bounds as Period)
   ) <= 126

define "主要規定三":
  "規則1-1=每次申請事前審查之療程以9週為限"
  and "規則1-2=總使用療程以18週為上限"


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if "初次申請" and ("規則1-1=初次使用Cetuximab與Irinotecan合併使用" or "規則1-2=用藥線別>1" or "規則2-1=治療已接受過含5-fluorouracil、irinotecan及oxaliplatin二線以上之細胞毒性治療失敗" or "規則2-2=用於治療具表皮生長因子受體表現型(EGFR expressing)" or "規則2-3=K-ras為原生型(wild type)" or "規則2-4-2=三個月內有影像檢查報告" or "規則2-4-3=癌症分期分數或結果為M>=1")
    then '<主要規定一：初次使用條件>\n' +
         (if "規則1-1=初次使用Cetuximab與Irinotecan合併使用" 
           then '● 規則1-1：Cetuximab與Irinotecan合併使用\n' else '') +
         (if "規則1-2=用藥線別>1" 
           then '● 規則1-2：用藥線別為二線以上\n' else '') +
         (if "規則2-1=治療已接受過含5-fluorouracil、irinotecan及oxaliplatin二線以上之細胞毒性治療失敗" 
           then '● 規則2-1：已接受過含5-fluorouracil、irinotecan及oxaliplatin二線以上之細胞毒性治療失敗\n' else '') +
         (if "規則2-2=用於治療具表皮生長因子受體表現型(EGFR expressing)" 
           then '● 規則2-2：用於治療具表皮生長因子受體表現型（EGFR expressing）\n' else '') +
         (if "規則2-3=K-ras為原生型(wild type)" 
           then '● 規則2-3：K-ras為原生型（wild type）\n' else '') +
         (if Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" 
           then '● 規則2-4-1：主要疾病之ICD代碼為C18、C19、C20、C21\n' else '') +
         (if "規則2-4-2=三個月內有影像檢查報告"
           then '● 規則2-4-2：三個月內有影像檢查報告\n' else '') +
         (if "規則2-4-3=癌症分期分數或結果為M>=1" 
           then '● 規則2-4-3：癌症分期為轉移性（M≥1）\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定二：續用條件
  (if "續用申請" and "規則1=提出客觀證據（如：影像學）證實無惡化，才可繼續使用" 
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '● 續用規則1：提出客觀證據（如：影像學）證實無惡化\n' +
         '\n'  
    else '') +
  
  // 主要規定三：藥品使用規則
  (if "規則1-1=每次申請事前審查之療程以9週為限" or "規則1-2=總使用療程以18週為上限"
    then '<主要規定三：藥品使用規則>\n' +
         (if "規則1-1=每次申請事前審查之療程以9週為限" 
           then '● 規則3-1：每次申請事前審查之療程以9週為限\n' else '') +
         (if "規則1-2=總使用療程以18週為上限" 
           then '● 規則3-2：總使用療程以18週為上限\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 代碼或條件不符
//============================================

define function "不符合項目_代碼或條件不符"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if "初次申請" and (not "規則1-2=用藥線別>1" or not "規則2-3=K-ras為原生型(wild type)" or not Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" or not "規則2-4-3=癌症分期分數或結果為M>=1")
    then '<主要規定一：初次使用條件>\n' +
         (if not "規則1-2=用藥線別>1" 
           then '▲ 規則1-2：用藥線別不為二線以上\n' else '') +
         (if not "規則2-3=K-ras為原生型(wild type)" 
           then '▲ 規則2-3：K-ras非原生型或未提供檢測結果\n' else '') +
         (if not Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" 
           then '▲ 規則2-4-1：主要疾病之ICD代碼未使用C18、C19、C20、C21\n' else '') +
         (if not "規則2-4-3=癌症分期分數或結果為M>=1" 
           then '▲ 規則2-4-3：癌症分期分數或結果不為M≥1\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定三：藥品使用規則 - 代碼條件不符
  (if not "規則1-1=每次申請事前審查之療程以9週為限" or not "規則1-2=總使用療程以18週為上限"
    then '<主要規定三：藥品使用規則>\n' +
         (if not "規則1-1=每次申請事前審查之療程以9週為限" 
           then '▲ 規則3-1：每次申請事前審查之療程超過9週上限\n' else '') +
         (if not "規則1-2=總使用療程以18週為上限" 
           then '▲ 規則3-2：總使用療程超過18週上限\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if "初次申請" and (not "規則1-1=初次使用Cetuximab與Irinotecan合併使用" or not "規則2-1=治療已接受過含5-fluorouracil、irinotecan及oxaliplatin二線以上之細胞毒性治療失敗" or not "規則2-2=用於治療具表皮生長因子受體表現型(EGFR expressing)" or not "規則2-4-2=三個月內有影像檢查報告")
    then '<主要規定一：初次使用條件>\n' +
         (if not "規則1-1=初次使用Cetuximab與Irinotecan合併使用"
           then '▲ 規則1-1：未提供Irinotecan處方\n' else '') +
         (if not "規則2-1=治療已接受過含5-fluorouracil、irinotecan及oxaliplatin二線以上之細胞毒性治療失敗"
           then '▲ 規則2-1：未提供含5-fluorouracil、irinotecan及oxaliplatin二線以上之細胞毒性治療失敗的歷史用藥資料\n' else '') +
         (if not "規則2-2=用於治療具表皮生長因子受體表現型(EGFR expressing)"
           then '▲ 規則2-2：未提供EGFR expressing檢測結果\n' else '') +
         (if not "規則2-4-2=三個月內有影像檢查報告"
           then '▲ 規則2-4-2：未提供三個月內影像檢查報告\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定二：續用條件 - 必要資料未填寫
  (if "續用申請" and not "規則1=提出客觀證據（如：影像學）證實無惡化，才可繼續使用"
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '▲ 續用規則1：未提供客觀證據（如：影像學）\n' +
         '\n'  
    else '')

//============================================
// 審核結果
//============================================

define "大腸直腸癌Cetuximab二線以上治療申請結果_布林":
  case
    when "初次申請" then (
      "規則1" and
      "規則2" and
      "規則1-1=每次申請事前審查之療程以9週為限" and  
      "規則1-2=總使用療程以18週為上限"
    )
    when "續用申請" then (
      "規則1=提出客觀證據（如：影像學）證實無惡化，才可繼續使用" and
      "規則1-1=每次申請事前審查之療程以9週為限" and  
      "規則1-2=總使用療程以18週為上限"
    )
    else false
  end

define "大腸直腸癌Cetuximab二線以上治療申請結果":
  if (
    "初次申請" and 
    "規則1" and
    "規則2" and
    "規則1-1=每次申請事前審查之療程以9週為限" and  
    "規則1-2=總使用療程以18週為上限"
  )
  then '✓通過：初次使用－大腸直腸癌 Cetuximab 第二線用藥申請'
  else if (
    "續用申請" and
    "規則1=提出客觀證據（如：影像學）證實無惡化，才可繼續使用" and
    "規則1-1=每次申請事前審查之療程以9週為限" and  
    "規則1-2=總使用療程以18週為上限"
  )
  then '✓通過：續用－大腸直腸癌 Cetuximab 第二線用藥申請'
  else if "初次申請"
  then '✖不通過：初次使用－大腸直腸癌 Cetuximab 第二線用藥申請'
  else if "續用申請"
  then '✖不通過：續用－大腸直腸癌 Cetuximab 第二線用藥申請'
  else '✖不通過：無法判定申請類型－大腸直腸癌 Cetuximab 第二線用藥申請'


//============================================
// 審核報告總結
//============================================

define "報告總結":
  '\n=== 大腸直腸癌之Cetuximab(二線治療) 申請審核報告 ===\n' +
  '\n【申請類型】' + "申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 代碼或條件不符】\n' +
  (if "不符合項目_代碼或條件不符"() = '' then '無\n' else "不符合項目_代碼或條件不符"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【申請結果】\n' +
  "大腸直腸癌Cetuximab二線以上治療申請結果" +
  '\n===============================================\n'