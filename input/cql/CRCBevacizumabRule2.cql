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
define "1規則1-1資料已填寫":
  exists (
    [MedicationRequest] MR
    where MR.medication is not null
      or MR.authoredOn is not null
  )

define "1規則1-1=Bevacizumab(除Zirabev以外)與含有5-fluorouracil/leucovorin/oxaliplatin的化學療法合併使用":
  Reusable."HasConcurrentMedicationOrders3"(
    CodeConcept.L01FG01exceptKC01146219,
    CodeConcept.L01BC02,
    CodeConcept.V03AF03,
    CodeConcept.L01XA03
  )
  and Reusable."醫令類別為1"

define "1規則1-1檢核結果":
  if not "1規則1-1資料已填寫"
    then '未提供Bevacizumab與含5-fluorouracil/leucovorin/oxaliplatin之化學療法併用資料'
  else if not "1規則1-1=Bevacizumab(除Zirabev以外)與含有5-fluorouracil/leucovorin/oxaliplatin的化學療法合併使用"
    then '未符合Bevacizumab與含5-fluorouracil/leucovorin/oxaliplatin之化學療法併用條件'
  else 'Bevacizumab與含有5-fluorouracil/leucovorin/oxaliplatin的化學療法合併使用'

//條件2
define "1規則2-1資料已填寫":
  exists (
    [MedicationRequest] MR
    where MR.medication is not null
      or MR.authoredOn is not null
  )

define "1規則2-1=先前接受過以fluoropyrimidine為基礎的化學療法併用cetuximab無效":
  Reusable."HasPriorConcurrentMedicationUse"(
    CodeConcept.L01FG01exceptKC01146219,
    CodeConcept."FluoropyrimidineWithTrifluridineTipiracil",
    CodeConcept.L01FE01
  )
  and Reusable."醫令類別為1"

define "1規則2-1檢核結果":
  if not "1規則2-1資料已填寫"
    then '未提供先前接受fluoropyrimidine為基礎化學療法併用cetuximab無效資料'
  else if not "1規則2-1=先前接受過以fluoropyrimidine為基礎的化學療法併用cetuximab無效"
    then '未符合先前接受fluoropyrimidine為基礎化學療法併用cetuximab無效條件'
  else '先前接受過以fluoropyrimidine為基礎的化學療法併用cetuximab無效'

//條件3
define "1規則2-2資料已填寫":
  exists (
    [MedicationRequest] MR
    where MR.medication is not null
      or MR.authoredOn is not null
  )

define "1規則2-2=先前接受過以fluoropyrimidine為基礎的化學療法併用panitumumab無效":
  Reusable."HasPriorConcurrentMedicationUse"(
    CodeConcept.L01FG01exceptKC01146219,
    CodeConcept."FluoropyrimidineWithTrifluridineTipiracil",
    CodeConcept.L01FE02
  )
  and Reusable."醫令類別為1"

define "1規則2-2檢核結果":
  if not "1規則2-2資料已填寫"
    then '未提供先前接受fluoropyrimidine為基礎化學療法併用panitumumab無效資料'
  else if not "1規則2-2=先前接受過以fluoropyrimidine為基礎的化學療法併用panitumumab無效"
    then '未符合先前接受fluoropyrimidine為基礎化學療法併用panitumumab無效條件'
  else '先前接受過以fluoropyrimidine為基礎的化學療法併用panitumumab無效'

define "1規則1=化學療法合併使用":
  "1規則1-1=Bevacizumab(除Zirabev以外)與含有5-fluorouracil/leucovorin/oxaliplatin的化學療法合併使用"
  and ("1規則2-1=先前接受過以fluoropyrimidine為基礎的化學療法併用cetuximab無效"
  or "1規則2-2=先前接受過以fluoropyrimidine為基礎的化學療法併用panitumumab無效")

define "1規則2":
  "1規則2-1=先前接受過以fluoropyrimidine為基礎的化學療法併用cetuximab無效"
  or "1規則2-2=先前接受過以fluoropyrimidine為基礎的化學療法併用panitumumab無效"

/*規則2*/
define "1規則3資料已填寫":
  exists (
    [MedicationRequest] MR
    where MR.medication is not null
      or MR.authoredOn is not null
  )

define "1規則3=曾接受過Bevacizumab治療":
  Reusable."HasPriorMedicationUse"(
    CodeConcept.L01FG01exceptKC01146219,
    CodeConcept.L01FG01exceptKC01146219
  )

define "1規則3檢核結果":
  if not "1規則3資料已填寫"
    then '未提供Bevacizumab過去用藥資料'
  else if "1規則3=曾接受過Bevacizumab治療"
    then '未符合「未曾接受過Bevacizumab治療」條件'
  else '未曾接受過Bevacizumab治療'

/*規則3*/
define "1規則3-1資料已填寫":
  exists (
    [Observation] RasObs
    where exists (
      RasObs.code.coding Cdg
      where Cdg.code = '69548-6'
        and Cdg in CodeConcept.LOINC
    )
    and (
      exists (RasObs.component)
        or exists (RasObs.interpretation)
    )
  )

define "1規則3-1=RAS基因沒有突變":
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

define "1規則3-1檢核結果":
  if not "1規則3-1資料已填寫"
    then '未提供RAS基因檢測結果資料'
  else if not "1規則3-1=RAS基因沒有突變"
    then '未符合RAS基因沒有突變條件'
  else 'RAS基因沒有突變'

/*規則4*/
//條件1
//Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"
define "1規則4-1資料已填寫":
  exists (
    [Claim] C
    where exists (C.diagnosis)
  )

define "1規則4-1=主要疾病之ICD-10代碼為C18、C19、C20、C21":
  Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"

define "1規則4-1檢核結果":
  if not "1規則4-1資料已填寫"
    then '未提供主要疾病之ICD資料'
  else if not "1規則4-1=主要疾病之ICD-10代碼為C18、C19、C20、C21"
    then '未符合主要疾病之ICD代碼為C18、C19、C20、C21條件'
  else '主要疾病之ICD-10代碼為C18、C19、C20、C21'

//條件2
define "1條件4-2資料已填寫":
  exists (
    [DiagnosticReport] O
    where exists (O.code.coding)
      and O.effective is not null
  )

define "1條件4-2=三個月內有影像檢查報告":
  exists (
    [DiagnosticReport] O
    where exists (
      O.code.coding Cdg
      where (
        Cdg in CodeConcept.ICD10PCS2023Image
        or Cdg in CodeConcept.ICD10PCS2014Image
      )
      and Cdg.code in CodeConcept.ImageReportCode
    )
    and O.effective is not null
    and FHIRHelpers.ToDateTime(O.effective) >= "本次申請起始日期" - 90 days
    and FHIRHelpers.ToDateTime(O.effective) <= "本次申請起始日期"
  ) 

define "1條件4-2檢核結果":
  if not "1條件4-2資料已填寫"
    then '未提供三個月內影像檢查報告資料'
  else if not "1條件4-2=三個月內有影像檢查報告"
    then '未符合「三個月內且代碼正確」之影像檢查報告條件'
  else '三個月內有影像檢查報告'

//條件3
define "1條件4-3資料已填寫":
  exists (
    [DiagnosticReport] O2
    where exists (O2.code.coding)
      and O2.effective is not null
  )

define "1條件4-3=三個月內有檢查報告":
  exists (
    [DiagnosticReport] O2
    where exists (
      O2.code.coding Cdg
      where Cdg in CodeConcept.LOINC
      and Cdg.code in CodeConcept.DiagnosticReportCode
    )
    and O2.effective is not null
    and FHIRHelpers.ToDateTime(O2.effective) >= "本次申請起始日期" - 90 days
    and FHIRHelpers.ToDateTime(O2.effective) <= "本次申請起始日期"
  ) 

define "1條件4-3檢核結果":
  if not "1條件4-3資料已填寫"
    then '未提供三個月內檢查報告資料'
  else if not "1條件4-3=三個月內有檢查報告"
    then '未符合「三個月內且代碼正確」之檢查報告條件'
  else '三個月內有檢查報告'

//條件4
define "1條件4-4資料已填寫":
  exists (
    [Observation] O
    where exists (
      O.code.coding Cdg
      where Cdg.code = '399390009'
        and Cdg in CodeConcept.SNOMED
    )
    and O.value is not null
  )

define "1條件4-4=癌症分期分數或結果為M>=1":
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

define "1條件4-4檢核結果":
  if not "1條件4-4資料已填寫"
    then '未提供癌症分期分數或結果資料'
  else if not "1條件4-4=癌症分期分數或結果為M>=1"
    then '未符合癌症分期分數或結果為M>=1條件'
  else '癌症分期分數或結果為M>=1'

//條件5
define "1條件4-5資料已填寫":
  exists (
    [Claim] C
    where exists (
      C.item I
      where exists (I.modifier)
    )
  )

define "1條件4-5=用藥線別為第二線":
  exists (
    [Claim] C
      where exists (
        C.item I
          where exists (
            I.modifier M
              where exists (
                M.coding Cdg
                  where Cdg in CodeConcept.NHILOT
                    and Cdg.code = '2'
              )
          )
      )
  )

define "1條件4-5檢核結果":
  if not "1條件4-5資料已填寫"
    then '未提供用藥線別資料'
  else if not "1條件4-5=用藥線別為第二線"
    then '未符合用藥線別為第二線條件'
  else '用藥線別為第二線'

define "1規則4=轉移性大腸或直腸癌病人的第二線治療":
  "1規則4-1=主要疾病之ICD-10代碼為C18、C19、C20、C21"
  and ("1條件4-2=三個月內有影像檢查報告"
  or "1條件4-3=三個月內有檢查報告")
  and "1條件4-4=癌症分期分數或結果為M>=1"
  and "1條件4-5=用藥線別為第二線"




define "主要規定一":
  Reusable."初次申請" and
  "1規則1=化學療法合併使用" 
  and not "1規則3=曾接受過Bevacizumab治療"
  and "1規則3-1=RAS基因沒有突變"
  and "1規則4=轉移性大腸或直腸癌病人的第二線治療"


//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

/*規則5*/
define "2規則5-1資料已填寫":
  exists (
    [DiagnosticReport] Report
    where exists (Report.code.coding)
      and Report.effective is not null
  )

define "2規則5-1=再次申請必須提出客觀證據（如：RECIST criteria）證實無惡化":
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
    and C in CodeConcept.NHITreatmentAst
   )
    and (TxAst.value as string in { 'CR', 'PR' })
  )
  )
  and Reusable."醫令類別為1"

define "2規則5-1檢核結果":
  if not "2規則5-1資料已填寫"
    then '未提供客觀證據（如：RECIST criteria）資料'
  else if not "2規則5-1=再次申請必須提出客觀證據（如：RECIST criteria）證實無惡化"
    then '未符合「三個月內且代碼正確」之影像或檢查報告條件'
  else '提出客觀證據（如：RECIST criteria）證實無惡化'

define "主要規定二":
  Reusable."續用申請" and
  "2規則5-1=再次申請必須提出客觀證據（如：RECIST criteria）證實無惡化"

define "2規則5":
  "2規則5-1=再次申請必須提出客觀證據（如：RECIST criteria）證實無惡化"


//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則6*/
define "3規則6-1資料已填寫":
  "本次申請紀錄" is not null

define "3規則6-1=每次申請事前審查之療程以12週為限":
  Reusable."HasMedicationPlanDurationWithin"(CodeConcept.L01FG01exceptKC01146219, 84)

define "3規則6-1檢核結果":
  if not "3規則6-1資料已填寫"
    then '未提供本次申請療程資料'
  else if not "3規則6-1=每次申請事前審查之療程以12週為限"
    then '未符合每次申請事前審查之療程以12週為上限條件'
  else '每次申請事前審查之療程以12週為限'

define "3條件6-2資料已填寫":
  exists (
    [MedicationRequest] MR
    where MR.medication is not null
      or MR.authoredOn is not null
  )

define "3條件6-2=使用總療程以24週為上限":
  Reusable."HasMedicationTotalDurationWithin"(CodeConcept.L01FG01exceptKC01146219, 168)

define "3條件6-2檢核結果":
  if not "3條件6-2資料已填寫"
    then '未提供使用總療程資料'
  else if not "3條件6-2=使用總療程以24週為上限"
    then '未符合使用總療程以24週為上限條件'
  else '使用總療程以24週為上限'

/*條件6*/
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



define "3條件6-3資料已填寫":
  PatientWeightValue is not null
  and "本次申請紀錄" is not null

define "3條件6-3=限5mg/kg每兩週一次(weight*5mg)":
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
        where DR.dose.value <= MaxAllowedDose
      )
    )
  )

define "3條件6-3檢核結果":
  if not "3條件6-3資料已填寫"
    then '未提供體重或本次申請給藥資料'
  else if not "3條件6-3=限5mg/kg每兩週一次(weight*5mg)"
    then '未符合5mg/kg(weight*5mg)且每兩週一次之給藥條件'
  else '限5mg/kg每兩週一次(weight*5mg)'


define "主要規定三":
  "3規則6-1=每次申請事前審查之療程以12週為限"
  and "3條件6-2=使用總療程以24週為上限"
  and "3條件6-3=限5mg/kg每兩週一次(weight*5mg)"

define "3規則6":
  "3規則6-1=每次申請事前審查之療程以12週為限"
  and "3條件6-2=使用總療程以24週為上限"
  and "3條件6-3=限5mg/kg每兩週一次(weight*5mg)"


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and ("1規則1=化學療法合併使用" or "1規則2-1=先前接受過以fluoropyrimidine為基礎的化學療法併用cetuximab無效" or "1規則2-2=先前接受過以fluoropyrimidine為基礎的化學療法併用panitumumab無效" or not "1規則3=曾接受過Bevacizumab治療" or "1規則3-1=RAS基因沒有突變" or "1規則4-1=主要疾病之ICD-10代碼為C18、C19、C20、C21" or "1條件4-2=三個月內有影像檢查報告" or "1條件4-3=三個月內有檢查報告" or "1條件4-4=癌症分期分數或結果為M>=1" or "1條件4-5=用藥線別為第二線")
    then '<主要規定一：初次使用條件>\n' +
         (if "1規則1-1=Bevacizumab(除Zirabev以外)與含有5-fluorouracil/leucovorin/oxaliplatin的化學療法合併使用" 
           then '● 1規則1-1：Bevacizumab(除Zirabev以外)與含有5-fluorouracil/leucovorin/oxaliplatin的化學療法合併使用\n' else '') +
         (if "1規則2-1=先前接受過以fluoropyrimidine為基礎的化學療法併用cetuximab無效" 
           then '● 1規則2-1：先前接受過以fluoropyrimidine為基礎的化學療法併用cetuximab無效\n' else '') +
         (if "1規則2-2=先前接受過以fluoropyrimidine為基礎的化學療法併用panitumumab無效" 
           then '● 1規則2-2：先前接受過以fluoropyrimidine為基礎的化學療法併用panitumumab無效\n' else '') +
         (if not "1規則3=曾接受過Bevacizumab治療" 
           then '● 1規則3：未曾接受過Bevacizumab治療\n' else '') +
         (if "1規則3-1=RAS基因沒有突變" 
           then '● 1規則3-1：RAS基因沒有突變\n' else '') +
         (if "1規則4-1=主要疾病之ICD-10代碼為C18、C19、C20、C21" 
           then '● 1規則4-1：主要疾病之ICD-10代碼為C18、C19、C20、C21\n' else '') +
         (if "1條件4-2=三個月內有影像檢查報告"
           then '● 1條件4-2：三個月內有影像檢查報告\n' else '') +
         (if "1條件4-3=三個月內有檢查報告"
           then '● 1條件4-3：三個月內有檢查報告\n' else '') +
         (if "1條件4-4=癌症分期分數或結果為M>=1" 
           then '● 1條件4-4：癌症分期為轉移性（M≥1）\n' else '') +
         (if "1條件4-5=用藥線別為第二線" 
           then '● 1條件4-5：用藥線別為第二線\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定二：續用條件
  (if Reusable."續用申請" and "2規則5-1=再次申請必須提出客觀證據（如：RECIST criteria）證實無惡化" 
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '● 2規則5-1：提出客觀證據（如：RECIST criteria）證實無惡化\n' +
         '\n'  
    else '') +
  
  // 主要規定三：藥品使用規則
  (if "3規則6-1=每次申請事前審查之療程以12週為限" or "3條件6-2=使用總療程以24週為上限" or "3條件6-3=限5mg/kg每兩週一次(weight*5mg)"
    then '<主要規定三：藥品使用規則>\n' +
         (if "3規則6-1=每次申請事前審查之療程以12週為限" 
           then '● 3規則6-1：每次申請事前審查之療程以12週為限\n' else '') +
         (if "3條件6-2=使用總療程以24週為上限" 
           then '● 3條件6-2：使用總療程以24週為上限\n' else '') +
         (if "3條件6-3=限5mg/kg每兩週一次(weight*5mg)" 
           then '● 3條件6-3：限5mg/kg每兩週一次(weight*5mg)\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 代碼或條件不符
//============================================

define function "不符合項目_代碼或條件不符"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if Reusable."初次申請" and (
      ("1規則1-1資料已填寫" and not "1規則1-1=Bevacizumab(除Zirabev以外)與含有5-fluorouracil/leucovorin/oxaliplatin的化學療法合併使用")
      or ("1規則2-1資料已填寫" and not "1規則2-1=先前接受過以fluoropyrimidine為基礎的化學療法併用cetuximab無效")
      or ("1規則2-2資料已填寫" and not "1規則2-2=先前接受過以fluoropyrimidine為基礎的化學療法併用panitumumab無效")
      or ("1規則3資料已填寫" and "1規則3=曾接受過Bevacizumab治療")
      or ("1規則3-1資料已填寫" and not "1規則3-1=RAS基因沒有突變")
      or ("1規則4-1資料已填寫" and not "1規則4-1=主要疾病之ICD-10代碼為C18、C19、C20、C21")
      or (("1條件4-2資料已填寫" or "1條件4-3資料已填寫") and not ("1條件4-2=三個月內有影像檢查報告" or "1條件4-3=三個月內有檢查報告"))
      or ("1條件4-4資料已填寫" and not "1條件4-4=癌症分期分數或結果為M>=1")
      or ("1條件4-5資料已填寫" and not "1條件4-5=用藥線別為第二線")
    )
    then '<主要規定一：初次使用條件>\n' +
         (if "1規則1-1資料已填寫" and not "1規則1-1=Bevacizumab(除Zirabev以外)與含有5-fluorouracil/leucovorin/oxaliplatin的化學療法合併使用"
           then '▲ 1規則1-1：' + "1規則1-1檢核結果" + '\n' else '') +
         (if "1規則2-1資料已填寫" and not "1規則2-1=先前接受過以fluoropyrimidine為基礎的化學療法併用cetuximab無效"
           then '▲ 1規則2-1：' + "1規則2-1檢核結果" + '\n' else '') +
         (if "1規則2-2資料已填寫" and not "1規則2-2=先前接受過以fluoropyrimidine為基礎的化學療法併用panitumumab無效"
           then '▲ 1規則2-2：' + "1規則2-2檢核結果" + '\n' else '') +
         (if "1規則3資料已填寫" and "1規則3=曾接受過Bevacizumab治療"
           then '▲ 1規則3：' + "1規則3檢核結果" + '\n' else '') +
         (if "1規則3-1資料已填寫" and not "1規則3-1=RAS基因沒有突變"
           then '▲ 1規則3-1：' + "1規則3-1檢核結果" + '\n' else '') +
         (if "1規則4-1資料已填寫" and not "1規則4-1=主要疾病之ICD-10代碼為C18、C19、C20、C21"
           then '▲ 1規則4-1：' + "1規則4-1檢核結果" + '\n' else '') +
         (if ("1條件4-2資料已填寫" or "1條件4-3資料已填寫") and not ("1條件4-2=三個月內有影像檢查報告" or "1條件4-3=三個月內有檢查報告")
           then '▲ 1條件4-2/4-3：未符合「三個月內且代碼正確」之影像或檢查報告條件\n' else '') +
         (if "1條件4-4資料已填寫" and not "1條件4-4=癌症分期分數或結果為M>=1"
           then '▲ 1條件4-4：' + "1條件4-4檢核結果" + '\n' else '') +
         (if "1條件4-5資料已填寫" and not "1條件4-5=用藥線別為第二線"
           then '▲ 1條件4-5：' + "1條件4-5檢核結果" + '\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定二：續用條件 - 代碼條件不符
  (if Reusable."續用申請" and "2規則5-1資料已填寫" and not "2規則5-1=再次申請必須提出客觀證據（如：RECIST criteria）證實無惡化"
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '▲ 未符合「三個月內且代碼正確」之影像或檢查報告條件\n' +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 代碼條件不符
  (if ("3規則6-1資料已填寫" and not "3規則6-1=每次申請事前審查之療程以12週為限")
      or ("3條件6-2資料已填寫" and not "3條件6-2=使用總療程以24週為上限")
      or ("3條件6-3資料已填寫" and not "3條件6-3=限5mg/kg每兩週一次(weight*5mg)")
    then '<主要規定三：藥品使用規則>\n' +
         (if "3規則6-1資料已填寫" and not "3規則6-1=每次申請事前審查之療程以12週為限"
           then '▲ 3規則6-1：' + "3規則6-1檢核結果" + '\n' else '') +
         (if "3條件6-2資料已填寫" and not "3條件6-2=使用總療程以24週為上限"
           then '▲ 3條件6-2：' + "3條件6-2檢核結果" + '\n' else '') +
         (if "3條件6-3資料已填寫" and not "3條件6-3=限5mg/kg每兩週一次(weight*5mg)"
           then '▲ 3條件6-3：' + "3條件6-3檢核結果" + '\n' else '')
    else '')

//============================================
// 不符合項目列表 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
      not "1規則1-1資料已填寫"
      or not "1規則2-1資料已填寫"
      or not "1規則2-2資料已填寫"
      or not "1規則3資料已填寫"
      or not "1規則3-1資料已填寫"
      or not "1規則4-1資料已填寫"
      or (not "1條件4-2資料已填寫" and not "1條件4-3資料已填寫")
      or not "1條件4-4資料已填寫"
      or not "1條件4-5資料已填寫"
    )
    then '<主要規定一：初次使用條件>\n' +
         (if not "1規則1-1資料已填寫"
           then '▲ 1規則1-1：' + "1規則1-1檢核結果" + '\n' else '') +
         (if not "1規則2-1資料已填寫"
           then '▲ 1規則2-1：' + "1規則2-1檢核結果" + '\n' else '') +
         (if not "1規則2-2資料已填寫"
           then '▲ 1規則2-2：' + "1規則2-2檢核結果" + '\n' else '') +
         (if not "1規則3資料已填寫"
           then '▲ 1規則3：' + "1規則3檢核結果" + '\n' else '') +
         (if not "1規則3-1資料已填寫"
           then '▲ 1規則3-1：' + "1規則3-1檢核結果" + '\n' else '') +
         (if not "1規則4-1資料已填寫"
           then '▲ 1規則4-1：' + "1規則4-1檢核結果" + '\n' else '') +
         (if not "1條件4-2資料已填寫" and not "1條件4-3資料已填寫"
           then '▲ 1條件4-2/4-3：未提供三個月內影像檢查報告或檢查報告資料\n' else '') +
         (if not "1條件4-4資料已填寫"
           then '▲ 1條件4-4：' + "1條件4-4檢核結果" + '\n' else '') +
         (if not "1條件4-5資料已填寫"
           then '▲ 1條件4-5：' + "1條件4-5檢核結果" + '\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and not "2規則5-1資料已填寫"
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '▲ 2規則5-1：' + "2規則5-1檢核結果" + '\n' +
         '\n'  
    else '') +

  // 主要規定三：藥品使用規則 - 必要資料未填寫
  (if not "3規則6-1資料已填寫" or not "3條件6-2資料已填寫" or not "3條件6-3資料已填寫"
    then '<主要規定三：藥品使用規則>\n' +
         (if not "3規則6-1資料已填寫"
           then '▲ 3規則6-1：' + "3規則6-1檢核結果" + '\n' else '') +
         (if not "3條件6-2資料已填寫"
           then '▲ 3條件6-2：' + "3條件6-2檢核結果" + '\n' else '') +
         (if not "3條件6-3資料已填寫"
           then '▲ 3條件6-3：' + "3條件6-3檢核結果" + '\n' else '')
    else '')

//============================================
// 審核結果
//============================================

define "大腸直腸癌Bevacizumab第二線治療申請結果_布林":
  case
    when Reusable."初次申請" then (
      "1規則1=化學療法合併使用" and
      not "1規則3=曾接受過Bevacizumab治療" and
      "1規則3-1=RAS基因沒有突變" and
      "1規則4=轉移性大腸或直腸癌病人的第二線治療" and
      "3規則6-1=每次申請事前審查之療程以12週為限" and  
      "3條件6-2=使用總療程以24週為上限" and
      "3條件6-3=限5mg/kg每兩週一次(weight*5mg)"
    )
    when Reusable."續用申請" then (
      "2規則5-1=再次申請必須提出客觀證據（如：RECIST criteria）證實無惡化" and
      "3規則6-1=每次申請事前審查之療程以12週為限" and  
      "3條件6-2=使用總療程以24週為上限" and
      "3條件6-3=限5mg/kg每兩週一次(weight*5mg)"
    )
    else false
  end


define "大腸直腸癌Bevacizumab第二線治療申請結果":
  if (
    Reusable."初次申請" and 
    "1規則1=化學療法合併使用" and
    not "1規則3=曾接受過Bevacizumab治療" and
    "1規則3-1=RAS基因沒有突變" and
    "1規則4=轉移性大腸或直腸癌病人的第二線治療" and
    "3規則6-1=每次申請事前審查之療程以12週為限" and  
    "3條件6-2=使用總療程以24週為上限" and
    "3條件6-3=限5mg/kg每兩週一次(weight*5mg)"
  )
  then '✓通過：初次使用－大腸直腸癌 Bevacizumab 第二線用藥申請'
  else if (
    Reusable."續用申請" and
    "2規則5-1=再次申請必須提出客觀證據（如：RECIST criteria）證實無惡化" and
    "3規則6-1=每次申請事前審查之療程以12週為限" and  
    "3條件6-2=使用總療程以24週為上限" and
    "3條件6-3=限5mg/kg每兩週一次(weight*5mg)"
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
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_代碼或條件不符"() = '' then '無\n' else "不符合項目_代碼或條件不符"()) +
  '\n【申請結果】\n' +
  "大腸直腸癌Bevacizumab第二線治療申請結果" +
  '\n===============================================\n'
