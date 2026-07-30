//大腸直腸癌_Bevacizumab給付規定(RAS基因沒有突變的轉移性大腸或直腸癌病人的第二線治療)
library CRCBevacizumabRule2 version '1.0.0'

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
define "1規則1-1=Bevacizumab(除Zirabev以外)與含有5-fluorouracil/leucovorin/oxaliplatin的化學療法合併使用":
  Reusable."HasConcurrentMedicationOrders3"(
    CodeConcept.L01FG01exceptKC01146219,
    CodeConcept.L01BC02,
    CodeConcept.V03AF03,
    CodeConcept.L01XA03
  )
  and Reusable."醫令類別為1"

//條件2
define "1規則1-2=先前接受過以fluoropyrimidine為基礎的化學療法併用cetuximab無效":
  Reusable."HasPriorConcurrentMedicationUse"(
    CodeConcept.L01FG01exceptKC01146219,
    CodeConcept."FluoropyrimidineWithTrifluridineTipiracil",
    CodeConcept.L01FE01
  )
  and Reusable."醫令類別為1"

//條件3
define "1規則1-3=先前接受過以fluoropyrimidine為基礎的化學療法併用panitumumab無效":
  Reusable."HasPriorConcurrentMedicationUse"(
    CodeConcept.L01FG01exceptKC01146219,
    CodeConcept."FluoropyrimidineWithTrifluridineTipiracil",
    CodeConcept.L01FE02
  )
  and Reusable."醫令類別為1"

define "1規則1=化學療法合併使用":
  "1規則1-1=Bevacizumab(除Zirabev以外)與含有5-fluorouracil/leucovorin/oxaliplatin的化學療法合併使用"
  and ("1規則1-2=先前接受過以fluoropyrimidine為基礎的化學療法併用cetuximab無效"
  or "1規則1-3=先前接受過以fluoropyrimidine為基礎的化學療法併用panitumumab無效")

/*規則2*/
define "1規則2=曾接受過Bevacizumab治療":
  Reusable."HasPriorMedicationUse"(
    CodeConcept.L01FG01exceptKC01146219,
    CodeConcept.L01FG01exceptKC01146219
  )

/*規則3*/
define "1規則3=RAS基因沒有突變":
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

/*規則4*/
//條件1
//Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"
define "ICD代碼檢核_布林值": Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"

//條件2
define "1規則4-2=三個月內有影像檢查報告":
  Reusable."HasRecentImageReport"(CodeConcept.ImageReportCode, "本次申請起始日期")

//條件3
define "1規則4-3=三個月內有檢查報告":
  Reusable."HasRecentDiagnosticReport"(CodeConcept.DiagnosticReportCode, "本次申請起始日期")

//條件4
define "1規則4-4=癌症分期分數或結果為M>=1":
  Reusable."癌症分期分數或結果為M>=1"

//條件5
define "1規則4-5=用藥線別為第二線":
  Reusable."HasLineOfTherapy"('2')

define "1規則4=轉移性大腸或直腸癌病人的第二線治療":
  Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"
  and ("1規則4-2=三個月內有影像檢查報告"
  or "1規則4-3=三個月內有檢查報告")
  and "1規則4-4=癌症分期分數或結果為M>=1"
  and "1規則4-5=用藥線別為第二線"




define "主要規定一":
  Reusable."初次申請" and
  "1規則1=化學療法合併使用" 
  and not "1規則2=曾接受過Bevacizumab治療"
  and "1規則3=RAS基因沒有突變"
  and "1規則4=轉移性大腸或直腸癌病人的第二線治療"


//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

/*規則1*/
define "2規則1=再次申請必須提出客觀證據（如：RECIST criteria）證實無惡化":
  exists (
    [MedicationRequest] MRPlan
     where MRPlan.intent = 'plan'
     and exists (
        MRPlan.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.L01FG01exceptKC01146219
      )
  and
  exists (
   [Observation] TxAst
   where TxAst.status = 'final'
   and exists (
    TxAst.code.coding C
    where C.code = 'REC1'
    and C.system in CodeConcept.NHITreatmentAst
   )
    and (TxAst.value as string in { 'CR', 'PR' })
  )
  )
  and Reusable."醫令類別為1"

define "主要規定二":
  Reusable."續用申請" and
  "2規則1=再次申請必須提出客觀證據（如：RECIST criteria）證實無惡化"


//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
define "3規則1=每次申請事前審查之療程以12週為限":
  Reusable."HasMedicationPlanDurationWithin"(CodeConcept.L01FG01exceptKC01146219, 84)

/*規則2*/
define "3規則2=使用總療程以24週為上限":
  Reusable."HasMedicationTotalDurationWithin"(CodeConcept.L01FG01exceptKC01146219, 168)

/*規則3*/
define "PatientWeight":
  First(
    [Claim] C
      return First(
        C.supportingInfo Cs
          where exists (
            Cs.category.coding coding
              where coding in CodeConcept.NHIPASSupportingInfoType
                and coding.code = 'weight'
          )
          return (Cs.value as FHIR.Quantity)
      )
  )

define "PatientWeightValue":
  PatientWeight.value  // 單位：kg

define "MaxAllowedDose":
  if PatientWeightValue is not null
  then PatientWeightValue * 5  // 單位：mg
  else null



define "3規則3-3=限5mg/kg每兩週一次(weight*5mg)":
  PatientWeightValue is not null
  and exists (
    [MedicationRequest] M
    where M.intent = 'plan'
    and exists (
      M.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
      and Cdg.code in CodeConcept.L01FG01exceptKC01146219
    )
    and exists (
      M.dosageInstruction DI
      where exists (
        DI.timing.code.coding C where C.code = 'Q2W'
      )
      and exists (
        DI.doseAndRate DR
        where DR.dose.unit = 'mg'
        and DR.dose.value <= MaxAllowedDose
      )
    )
  )


define "主要規定三":
  "3規則1=每次申請事前審查之療程以12週為限"
  and "3規則2=使用總療程以24週為上限"
  and "3規則3-3=限5mg/kg每兩週一次(weight*5mg)"


//============================================
// 檢核結果用：必要資料存在判斷
//============================================

define "Bevacizumab第二線申請資料存在":
  Reusable."HasMedicationPlanRecord"(CodeConcept.L01FG01exceptKC01146219)

define "化學療法併用資料存在":
  Reusable."HasMedicationRecord"(CodeConcept.L01BC02)
  or Reusable."HasMedicationRecord"(CodeConcept.V03AF03)
  or Reusable."HasMedicationRecord"(CodeConcept.L01XA03)
  or Reusable."HasMedicationRecord"(CodeConcept."FluoropyrimidineWithTrifluridineTipiracil")
  or Reusable."HasMedicationRecord"(CodeConcept.L01FE01)
  or Reusable."HasMedicationRecord"(CodeConcept.L01FE02)

define "RAS基因檢測資料存在":
  Reusable."RAS基因檢測資料存在"

define "影像或檢查報告資料存在":
  Reusable."影像或檢查報告資料存在"

define "癌症分期資料存在":
  Reusable."癌症分期資料存在"

define "用藥線別資料存在":
  Reusable."用藥線別資料存在"

define "續用客觀證據資料存在":
  Reusable."治療反應評估資料存在"

define "療程期間資料存在":
  Reusable."HasMedicationPlanTiming"(CodeConcept.L01FG01exceptKC01146219)

define "劑量資料存在":
  PatientWeightValue is not null
  and exists (
    [MedicationRequest] M
    where M.intent = 'plan'
      and Reusable."HasMedicationCode"(M, CodeConcept.L01FG01exceptKC01146219)
      and M.dosageInstruction is not null
  )

define "必要資料皆存在":
  not (
    (Reusable."初次申請" and (
      not "Bevacizumab第二線申請資料存在"
      or not "化學療法併用資料存在"
      or not "RAS基因檢測資料存在"
      or not Reusable."主要疾病ICD診斷資料存在"
      or not "影像或檢查報告資料存在"
      or not "癌症分期資料存在"
      or not "用藥線別資料存在"
      or not "劑量資料存在"
    ))
    or (Reusable."續用申請" and (
      not "Bevacizumab第二線申請資料存在"
      or not "續用客觀證據資料存在"
      or not "劑量資料存在"
    ))
    or not "療程期間資料存在"
  )


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and ("1規則1=化學療法合併使用" or not "1規則2=曾接受過Bevacizumab治療" or "1規則3=RAS基因沒有突變" or "1規則4-2=三個月內有影像檢查報告" or "1規則4-3=三個月內有檢查報告" or "1規則4-4=癌症分期分數或結果為M>=1" or "1規則4-5=用藥線別為第二線")
    then '<主要規定一：初次使用條件>\n' +
         (if "1規則1-1=Bevacizumab(除Zirabev以外)與含有5-fluorouracil/leucovorin/oxaliplatin的化學療法合併使用" 
           then '● 規則1-1：Bevacizumab(除Zirabev以外)與含有5-fluorouracil/leucovorin/oxaliplatin的化學療法合併使用（參考資訊）\n' else '') +
         (if "1規則1-2=先前接受過以fluoropyrimidine為基礎的化學療法併用cetuximab無效" 
           then '● 規則1-2：先前接受過以fluoropyrimidine為基礎的化學療法併用cetuximab無效（參考資訊）\n' else '') +
         (if "1規則1-3=先前接受過以fluoropyrimidine為基礎的化學療法併用panitumumab無效" 
           then '● 規則1-3：先前接受過以fluoropyrimidine為基礎的化學療法併用panitumumab無效（參考資訊）\n' else '') +
         (if not "1規則2=曾接受過Bevacizumab治療" 
           then '● 規則2：未曾接受過Bevacizumab治療\n' else '') +
         (if "1規則3=RAS基因沒有突變" 
           then '● 規則3：RAS基因沒有突變\n' else '') +
         (if Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" 
           then '● 規則4-1：主要疾病之ICD-10代碼為C18、C19、C20、C21\n' else '') +
         (if "1規則4-2=三個月內有影像檢查報告"
           then '● 規則4-2：三個月內有影像檢查報告\n' else '') +
         (if "1規則4-3=三個月內有檢查報告"
           then '● 規則4-3：三個月內有檢查報告\n' else '') +
         (if "1規則4-4=癌症分期分數或結果為M>=1" 
           then '● 規則4-4：癌症分期為轉移性（M≥1）\n' else '') +
         (if "1規則4-5=用藥線別為第二線" 
           then '● 規則4-5：用藥線別為第二線\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定二：續用條件
  (if Reusable."續用申請" and "2規則1=再次申請必須提出客觀證據（如：RECIST criteria）證實無惡化" 
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '● 續用規則1：提出客觀證據（如：RECIST criteria）證實無惡化\n' +
         '\n'  
    else '') +
  
  // 主要規定三：藥品使用規則
  (if "3規則1=每次申請事前審查之療程以12週為限" or "3規則2=使用總療程以24週為上限" or "3規則3-3=限5mg/kg每兩週一次(weight*5mg)"
    then '<主要規定三：藥品使用規則>\n' +
         (if "3規則1=每次申請事前審查之療程以12週為限" 
           then '● 規則3-1：每次申請事前審查之療程以12週為限（參考資訊）\n' else '') +
         (if "3規則2=使用總療程以24週為上限" 
           then '● 規則3-2：使用總療程以24週為上限（參考資訊）\n' else '') +
         (if "3規則3-3=限5mg/kg每兩週一次(weight*5mg)" 
           then '● 規則3-3：限5mg/kg每兩週一次(weight*5mg)\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 條件或代碼不符合
//============================================

define function "不符合項目_條件或代碼不符合"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if Reusable."初次申請" and (
    "1規則2=曾接受過Bevacizumab治療"
    or ("RAS基因檢測資料存在" and not "1規則3=RAS基因沒有突變")
    or (Reusable."主要疾病ICD診斷資料存在" and not Reusable."主要疾病之ICD-10使用C18、C19、C20、C21")
    or ("影像或檢查報告資料存在" and not ("1規則4-2=三個月內有影像檢查報告" or "1規則4-3=三個月內有檢查報告"))
    or ("癌症分期資料存在" and not "1規則4-4=癌症分期分數或結果為M>=1")
    or ("用藥線別資料存在" and not "1規則4-5=用藥線別為第二線")
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "1規則2=曾接受過Bevacizumab治療" 
           then '▲ 規則2：曾接受過Bevacizumab治療\n' else '') +
         (if "RAS基因檢測資料存在" and not "1規則3=RAS基因沒有突變" 
           then '▲ 規則3：RAS基因檢測結果不符合（需無突變）\n' else '') +
         (if Reusable."主要疾病ICD診斷資料存在" and not Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" 
           then '▲ 規則4-1：主要疾病之ICD代碼未使用C18、C19、C20、C21\n' else '') +
         (if "影像或檢查報告資料存在" and not ("1規則4-2=三個月內有影像檢查報告" or "1規則4-3=三個月內有檢查報告")
           then '▲ 規則4-2/4-3：未符合三個月內且代碼正確之影像報告或檢查報告條件\n' else '') +
         (if "癌症分期資料存在" and not "1規則4-4=癌症分期分數或結果為M>=1" 
           then '▲ 規則4-4：癌症分期分數或結果不為M>=1\n' else '') +
         (if "用藥線別資料存在" and not "1規則4-5=用藥線別為第二線" 
           then '▲ 規則4-5：用藥線別不為第二線\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定三：藥品使用規則 - 代碼條件不符
  (if ("療程期間資料存在" and not "3規則1=每次申請事前審查之療程以12週為限") or ("療程期間資料存在" and not "3規則2=使用總療程以24週為上限") or ("劑量資料存在" and not "3規則3-3=限5mg/kg每兩週一次(weight*5mg)")
    then '<主要規定三：藥品使用規則>\n' +
         (if "療程期間資料存在" and not "3規則1=每次申請事前審查之療程以12週為限" 
           then '▲ 規則3-1：每次申請事前審查之療程超過12週上限（參考資訊）\n' else '') +
         (if "療程期間資料存在" and not "3規則2=使用總療程以24週為上限" 
           then '▲ 規則3-2：使用總療程超過24週上限（參考資訊）\n' else '') +
         (if "劑量資料存在" and not "3規則3-3=限5mg/kg每兩週一次(weight*5mg)" 
           then '▲ 規則3-3：給藥劑量不符合5mg/kg(weight*5mg)，或給藥頻率不符合每兩週一次之規定\n' else '')
    else '')

//============================================
// 不符合項目列表 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
    not "Bevacizumab第二線申請資料存在"
    or not "化學療法併用資料存在"
    or not "RAS基因檢測資料存在"
    or not Reusable."主要疾病ICD診斷資料存在"
    or not "影像或檢查報告資料存在"
    or not "癌症分期資料存在"
    or not "用藥線別資料存在"
    or not "劑量資料存在"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "Bevacizumab第二線申請資料存在"
           then '▲ 申請醫令：未提供Bevacizumab第二線申請醫令資料\n' else '') +
         (if not "化學療法併用資料存在"
           then '▲ 規則1：未提供化學療法併用資料（需有 5-fluorouracil/leucovorin/oxaliplatin 之處方，且先前接受過以 fluoropyrimidine 為基礎的化學療法併用 cetuximab 或 panitumumab 無效）（參考資訊）\n' else '') +
         (if not "RAS基因檢測資料存在"
           then '▲ 規則3：未提供RAS基因檢測資料\n' else '') +
         (if not Reusable."主要疾病ICD診斷資料存在"
           then '▲ 規則4-1：未提供主要疾病ICD診斷資料\n' else '') +
         (if not "影像或檢查報告資料存在"
           then '▲ 規則4-2/4-3：未提供三個月內影像檢查報告或檢查報告\n' else '') +
         (if not "癌症分期資料存在"
           then '▲ 規則4-4：未提供癌症分期分數或結果資料\n' else '') +
         (if not "用藥線別資料存在"
           then '▲ 規則4-5：未提供用藥線別資料\n' else '') +
         (if not "劑量資料存在"
           then '▲ 規則3-3：未提供體重或劑量頻率資料\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (not "Bevacizumab第二線申請資料存在" or not "續用客觀證據資料存在" or not "劑量資料存在")
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if not "Bevacizumab第二線申請資料存在" then '▲ 申請醫令：未提供Bevacizumab第二線申請醫令資料\n' else '') +
         (if not "續用客觀證據資料存在" then '▲ 續用規則1：未提供客觀證據（如：RECIST criteria）\n' else '') +
         (if not "劑量資料存在" then '▲ 規則3-3：未提供體重或劑量頻率資料\n' else '') +
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

define "大腸直腸癌Bevacizumab第二線治療申請結果_布林":
  case
    when Reusable."初次申請" then (
      not "1規則2=曾接受過Bevacizumab治療" and
      "1規則3=RAS基因沒有突變" and
      "1規則4=轉移性大腸或直腸癌病人的第二線治療" and
      "3規則3-3=限5mg/kg每兩週一次(weight*5mg)"
    )
    when Reusable."續用申請" then (
      "2規則1=再次申請必須提出客觀證據（如：RECIST criteria）證實無惡化" and
      "3規則3-3=限5mg/kg每兩週一次(weight*5mg)"
    )
    else false
  end


define "大腸直腸癌Bevacizumab第二線治療申請結果":
  if (
    Reusable."初次申請" and 
    not "1規則2=曾接受過Bevacizumab治療" and
    "1規則3=RAS基因沒有突變" and
    "1規則4=轉移性大腸或直腸癌病人的第二線治療" and
    "3規則3-3=限5mg/kg每兩週一次(weight*5mg)"
  )
  then '✓通過：初次使用－大腸直腸癌 Bevacizumab 第二線用藥申請'
  else if (
    Reusable."續用申請" and
    "2規則1=再次申請必須提出客觀證據（如：RECIST criteria）證實無惡化" and
    "3規則3-3=限5mg/kg每兩週一次(weight*5mg)"
  )
  then '✓通過：續用－大腸直腸癌 Bevacizumab 第二線用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－大腸直腸癌 Bevacizumab 第二線用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－大腸直腸癌 Bevacizumab 第二線用藥申請'
  else '✖不通過：無法判定申請類型－大腸直腸癌 Bevacizumab 第二線用藥申請'


//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 大腸直腸癌之Bevacizumab(二線治療) 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "大腸直腸癌Bevacizumab第二線治療申請結果" +
  '\n===============================================\n'
