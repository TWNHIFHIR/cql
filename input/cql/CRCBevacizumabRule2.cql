//大腸直腸癌_Bevacizumab給付規定(RAS基因沒有突變的轉移性大腸或直腸癌病人的第二線治療)
library CRCBevacizumabRule2 version '1.0.0'

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
define "規則1-1=Bevacizumab(除Zirabev以外)與含有5-fluorouracil/leucovorin/oxaliplatin的化學療法合併使用":
(
  // Bevacizumab（不包含Zirabev）申請（作為基準時間）
  exists (
    [MedicationRequest] MRPlan
    where MRPlan.intent = 'plan'
    and exists (
      MRPlan.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
      and Cdg.code in CodeConcept.L01FG01exceptKC01146219
    )
    and MRPlan.dosageInstruction[0].timing.repeat.bounds is Period
    and (start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
    and (end of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period)) is not null

    // 存在 Fluorouracil 處方且與 Bevacizumab 時間重疊
    and exists (
      [MedicationRequest] MROrder1
      where MROrder1.intent = 'order'
      and exists (
        MROrder1.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.L01BC02
      )
      and Reusable."HasValidTiming"(MROrder1)
      and MROrder1.dosageInstruction[0].timing.repeat.bounds is Period
      and (start of (MROrder1.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
      and (end of (MROrder1.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
      and (start of (MROrder1.dosageInstruction[0].timing.repeat.bounds as Period))
          <= (end of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period))
      and (end of (MROrder1.dosageInstruction[0].timing.repeat.bounds as Period))
          >= (start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period))
    )

    // 存在 Oxaliplatin 處方且藥物處方的起始及終止日期涵蓋在事前審查藥品申請日期使用的區間內
    and exists (
      [MedicationRequest] MROrder2
      where MROrder2.intent = 'order'
      and exists (
        MROrder2.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.L01XA03
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

    // 存在 Leucovorin 處方且藥物處方的起始及終止日期涵蓋在事前審查藥品申請日期使用的區間內
    and exists (
      [MedicationRequest] MROrder3
      where MROrder3.intent = 'order'
      and exists (
        MROrder3.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.V03AF03
      )
      and Reusable."HasValidTiming"(MROrder3)
      and MROrder3.dosageInstruction[0].timing.repeat.bounds is Period
      and (start of (MROrder3.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
      and (end of (MROrder3.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
      and (start of (MROrder3.dosageInstruction[0].timing.repeat.bounds as Period))
          <= (end of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period))
      and (end of (MROrder3.dosageInstruction[0].timing.repeat.bounds as Period))
          >= (start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period))
    )
  )
)
and Reusable."醫令類別為1"

//條件2
define "規則1-2=先前接受過以fluoropyrimidine為基礎的化學療法併用cetuximab無效":
  exists (
    [MedicationRequest] CurrentBevacizumab
    where CurrentBevacizumab.intent = 'plan'
    and exists (
      CurrentBevacizumab.medication.coding BevaCoding
      where BevaCoding in CodeConcept.NHIMedication
      and BevaCoding.code in CodeConcept.L01FG01exceptKC01146219
    )
    and Reusable."HasValidTiming"(CurrentBevacizumab)
    and exists (
      [MedicationRequest] FluoropyrimidineMR
      where FluoropyrimidineMR.intent = 'order'
      and exists (
        FluoropyrimidineMR.medication.coding FluoroCoding
        where FluoroCoding in CodeConcept.NHIMedication
        and (
        FluoroCoding.code in CodeConcept.L01BC59 
        or FluoroCoding.code in CodeConcept.L01BC02 
        or FluoroCoding.code in CodeConcept.L01BC03 
        or FluoroCoding.code in CodeConcept.L01BC06 
        or FluoroCoding.code in CodeConcept.L01BC53
        )
      )
      and Reusable."HasValidTiming"(FluoropyrimidineMR)
      and Reusable."GetEndTime"(FluoropyrimidineMR) <= Reusable."GetStartTime"(CurrentBevacizumab)
      and exists (
        [MedicationRequest] CetuximabMR
        where CetuximabMR.intent = 'order'
        and exists (
          CetuximabMR.medication.coding CetuximabCoding
          where CetuximabCoding in CodeConcept.NHIMedication
          and CetuximabCoding.code in CodeConcept.L01FE01
        )
          and (
          Reusable."GetStartTime"(CetuximabMR) <= Reusable."GetEndTime"(FluoropyrimidineMR)
          and Reusable."GetEndTime"(CetuximabMR) >= Reusable."GetStartTime"(FluoropyrimidineMR)
        )
        and Reusable."GetEndTime"(CetuximabMR) <= Reusable."GetStartTime"(CurrentBevacizumab)
      )
    )
  )
  and Reusable."醫令類別為1"

//條件3
define "規則1-3=先前接受過以fluoropyrimidine為基礎的化學療法併用panitumumab無效":
  exists (
    [MedicationRequest] CurrentBevacizumab
    where CurrentBevacizumab.intent = 'plan'
    and exists (
      CurrentBevacizumab.medication.coding BevaCoding
      where BevaCoding in CodeConcept.NHIMedication
      and BevaCoding.code in CodeConcept.L01FG01exceptKC01146219
    )
    and Reusable."HasValidTiming"(CurrentBevacizumab)
    and exists (
      [MedicationRequest] FluoropyrimidineMR
      where FluoropyrimidineMR.intent = 'order'
      and exists (
        FluoropyrimidineMR.medication.coding FluoroCoding
        where FluoroCoding in CodeConcept.NHIMedication
        and (
        FluoroCoding.code in CodeConcept.L01BC59 
        or FluoroCoding.code in CodeConcept.L01BC02 
        or FluoroCoding.code in CodeConcept.L01BC03 
        or FluoroCoding.code in CodeConcept.L01BC06 
        or FluoroCoding.code in CodeConcept.L01BC53
        )
      )
      and Reusable."HasValidTiming"(FluoropyrimidineMR)
      and Reusable."GetEndTime"(FluoropyrimidineMR) <= Reusable."GetStartTime"(CurrentBevacizumab)
      and exists (
        [MedicationRequest] PanitumumabMR
        where PanitumumabMR.intent = 'order'
        and exists (
          PanitumumabMR.medication.coding PanitumumabCoding
          where PanitumumabCoding in CodeConcept.NHIMedication
          and PanitumumabCoding.code in CodeConcept.L01FE02
        )
        and (
          Reusable."GetStartTime"(PanitumumabMR) <= Reusable."GetEndTime"(FluoropyrimidineMR)
          and Reusable."GetEndTime"(PanitumumabMR) >= Reusable."GetStartTime"(FluoropyrimidineMR)
        )
        and Reusable."GetEndTime"(PanitumumabMR) <= Reusable."GetStartTime"(CurrentBevacizumab)
      )
    )
  )
  and Reusable."醫令類別為1"

define "規則1=化學療法合併使用":
  "規則1-1=Bevacizumab(除Zirabev以外)與含有5-fluorouracil/leucovorin/oxaliplatin的化學療法合併使用"
  and ("規則1-2=先前接受過以fluoropyrimidine為基礎的化學療法併用cetuximab無效"
  or "規則1-3=先前接受過以fluoropyrimidine為基礎的化學療法併用panitumumab無效")

/*規則2*/
define "規則2=未曾接受過Bevacizumab治療":
  not exists (
    [MedicationRequest] NoBevacizumabMR
    where NoBevacizumabMR.intent = 'order'
    and exists (
      NoBevacizumabMR.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
      and Cdg.code in CodeConcept.L01FG01exceptKC01146219
    )
    and Reusable."HasValidTiming"(NoBevacizumabMR)
  )

/*規則3*/
define "規則3=RAS基因沒有突變":
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
define "規則4-2=三個月內有影像檢查報告":
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
    and FHIRHelpers.ToDateTime(O.effective) >= Today() - 90 days
    and FHIRHelpers.ToDateTime(O.effective) <= Today()
  ) 

//條件3
define "規則4-3=三個月內有檢查報告":
  exists (
    [DiagnosticReport] O2
    where exists (
      O2.code.coding Cdg
      where Cdg in CodeConcept.LOINC
      and Cdg.code in CodeConcept.DiagnosticReport
    )
    and O2.effective is not null
    and FHIRHelpers.ToDateTime(O2.effective) >= Today() - 90 days
    and FHIRHelpers.ToDateTime(O2.effective) <= Today()
  ) 

//條件4
define "規則4-4=癌症分期分數或結果為M>=1":
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

//條件5
define "規則4-5=用藥線別為第二線":
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

define "規則4=轉移性大腸或直腸癌病人的第二線治療":
  Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"
  and ("規則4-2=三個月內有影像檢查報告"
  or "規則4-3=三個月內有檢查報告")
  and "規則4-4=癌症分期分數或結果為M>=1"
  and "規則4-5=用藥線別為第二線"




define "主要規定一":
  "初次申請" and
  "規則1=化學療法合併使用" 
  and "規則2=未曾接受過Bevacizumab治療"
  and "規則3=RAS基因沒有突變"
  and "規則4=轉移性大腸或直腸癌病人的第二線治療"


//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

/*規則1*/
define "規則1=再次申請必須提出客觀證據（如：RECIST criteria）證實無惡化":
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
  "續用申請" and
  "規則1=再次申請必須提出客觀證據（如：RECIST criteria）證實無惡化"


//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
define "規則1=每次申請事前審查之療程以12週為限":
  exists [MedicationRequest] MRPlan
  where MRPlan.intent = 'plan'
  and exists (
  MRPlan.medication.coding Cdg
  where Cdg in CodeConcept.NHIMedication
  and Cdg.code in CodeConcept.L01FG01exceptKC01146219
   )
  and days between
  start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period)
  and
  end of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period)
  <= 84

/*規則2*/
define "規則2=使用總療程以24週為上限":
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
  and Cdg.code in CodeConcept.L01FG01exceptKC01146219
   )
  return
  days between
  start of (MRTotal.dosageInstruction[0].timing.repeat.bounds as Period)
  and
  end of (MRTotal.dosageInstruction[0].timing.repeat.bounds as Period)
   ) <= 168

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



define "規則3-3=限5mg/kg每兩週一次(weight*5mg)":
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
  "規則1=每次申請事前審查之療程以12週為限"
  and "規則2=使用總療程以24週為上限"
  and "規則3-3=限5mg/kg每兩週一次(weight*5mg)"


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if "初次申請" and ("規則1=化學療法合併使用" or "規則2=未曾接受過Bevacizumab治療" or "規則3=RAS基因沒有突變" or "規則4-2=三個月內有影像檢查報告" or "規則4-3=三個月內有檢查報告" or "規則4-4=癌症分期分數或結果為M>=1" or "規則4-5=用藥線別為第二線")
    then '<主要規定一：初次使用條件>\n' +
         (if "規則1-1=Bevacizumab(除Zirabev以外)與含有5-fluorouracil/leucovorin/oxaliplatin的化學療法合併使用" 
           then '● 規則1-1：Bevacizumab(除Zirabev以外)與含有5-fluorouracil/leucovorin/oxaliplatin的化學療法合併使用\n' else '') +
         (if "規則1-2=先前接受過以fluoropyrimidine為基礎的化學療法併用cetuximab無效" 
           then '● 規則1-2：先前接受過以fluoropyrimidine為基礎的化學療法併用cetuximab無效\n' else '') +
         (if "規則1-3=先前接受過以fluoropyrimidine為基礎的化學療法併用panitumumab無效" 
           then '● 規則1-3：先前接受過以fluoropyrimidine為基礎的化學療法併用panitumumab無效\n' else '') +
         (if "規則2=未曾接受過Bevacizumab治療" 
           then '● 規則2：未曾接受過Bevacizumab治療\n' else '') +
         (if "規則3=RAS基因沒有突變" 
           then '● 規則3：RAS基因沒有突變\n' else '') +
         (if Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" 
           then '● 規則4-1：主要疾病之ICD-10代碼為C18、C19、C20、C21\n' else '') +
         (if "規則4-2=三個月內有影像檢查報告"
           then '● 規則4-2：三個月內有影像檢查報告\n' else '') +
         (if "規則4-3=三個月內有檢查報告"
           then '● 規則4-3：三個月內有檢查報告\n' else '') +
         (if "規則4-4=癌症分期分數或結果為M>=1" 
           then '● 規則4-4：癌症分期為轉移性（M≥1）\n' else '') +
         (if "規則4-5=用藥線別為第二線" 
           then '● 規則4-5：用藥線別為第二線\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定二：續用條件
  (if "續用申請" and "規則1=再次申請必須提出客觀證據（如：RECIST criteria）證實無惡化" 
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '● 續用規則1：提出客觀證據（如：RECIST criteria）證實無惡化\n' +
         '\n'  
    else '') +
  
  // 主要規定三：藥品使用規則
  (if "規則1=每次申請事前審查之療程以12週為限" or "規則2=使用總療程以24週為上限" or "規則3-3=限5mg/kg每兩週一次(weight*5mg)"
    then '<主要規定三：藥品使用規則>\n' +
         (if "規則1=每次申請事前審查之療程以12週為限" 
           then '● 規則3-1：每次申請事前審查之療程以12週為限\n' else '') +
         (if "規則2=使用總療程以24週為上限" 
           then '● 規則3-2：使用總療程以24週為上限\n' else '') +
         (if "規則3-3=限5mg/kg每兩週一次(weight*5mg)" 
           then '● 規則3-3：限5mg/kg每兩週一次(weight*5mg)\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 代碼或條件不符
//============================================

define function "不符合項目_代碼或條件不符"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if "初次申請" and (not "規則2=未曾接受過Bevacizumab治療" or not "規則3=RAS基因沒有突變" or not Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" or not "規則4-4=癌症分期分數或結果為M>=1" or not "規則4-5=用藥線別為第二線")
    then '<主要規定一：初次使用條件>\n' +
         (if not "規則2=未曾接受過Bevacizumab治療" 
           then '▲ 規則2：曾接受過Bevacizumab治療\n' else '') +
         (if not "規則3=RAS基因沒有突變" 
           then '▲ 規則3：RAS基因有突變或未提供檢測結果\n' else '') +
         (if not Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" 
           then '▲ 規則4-1：主要疾病之ICD代碼未使用C18、C19、C20、C21\n' else '') +
         (if not "規則4-4=癌症分期分數或結果為M>=1" 
           then '▲ 規則4-4：癌症分期分數或結果不為M>=1\n' else '') +
         (if not "規則4-5=用藥線別為第二線" 
           then '▲ 規則4-5：用藥線別不為第二線\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定三：藥品使用規則 - 代碼條件不符
  (if not "規則1=每次申請事前審查之療程以12週為限" or not "規則2=使用總療程以24週為上限" or not "規則3-3=限5mg/kg每兩週一次(weight*5mg)"
    then '<主要規定三：藥品使用規則>\n' +
         (if not "規則1=每次申請事前審查之療程以12週為限" 
           then '▲ 規則3-1：每次申請事前審查之療程超過12週上限\n' else '') +
         (if not "規則2=使用總療程以24週為上限" 
           then '▲ 規則3-2：使用總療程超過24週上限\n' else '') +
         (if not "規則3-3=限5mg/kg每兩週一次(weight*5mg)" 
           then '▲ 規則3-3：給藥劑量不符合5mg/kg(weight*5mg)，或給藥頻率不符合每兩週一次之規定\n' else '')
    else '')

//============================================
// 不符合項目列表 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if "初次申請" and (not "規則1=化學療法合併使用" or not ("規則4-2=三個月內有影像檢查報告" or "規則4-3=三個月內有檢查報告"))
    then '<主要規定一：初次使用條件>\n' +
         (if not "規則1=化學療法合併使用"
           then '▲ 規則1：未提供化學療法併用資料（需有 5-fluorouracil/leucovorin/oxaliplatin 之處方，且先前接受過以 fluoropyrimidine 為基礎的化學療法併用 cetuximab 或 panitumumab 無效）\n' else '') +
         (if not ("規則4-2=三個月內有影像檢查報告" or "規則4-3=三個月內有檢查報告")
           then '▲ 規則4-2/4-3：未提供三個月內影像檢查報告或檢查報告\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定二：續用條件 - 必要資料未填寫
  (if "續用申請" and not "規則1=再次申請必須提出客觀證據（如：RECIST criteria）證實無惡化"
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '▲ 續用規則1：未提供客觀證據（如：RECIST criteria）\n' +
         '\n'  
    else '')

//============================================
// 審核結果
//============================================

define "大腸直腸癌Bevacizumab第二線治療申請結果_布林":
  case
    when "初次申請" then (
      "規則1=化學療法合併使用" and
      "規則2=未曾接受過Bevacizumab治療" and
      "規則3=RAS基因沒有突變" and
      "規則4=轉移性大腸或直腸癌病人的第二線治療" and
      "規則1=每次申請事前審查之療程以12週為限" and  
      "規則2=使用總療程以24週為上限" and
      "規則3-3=限5mg/kg每兩週一次(weight*5mg)"
    )
    when "續用申請" then (
      "規則1=再次申請必須提出客觀證據（如：RECIST criteria）證實無惡化" and
      "規則1=每次申請事前審查之療程以12週為限" and  
      "規則2=使用總療程以24週為上限" and
      "規則3-3=限5mg/kg每兩週一次(weight*5mg)"
    )
    else false
  end


define "大腸直腸癌Bevacizumab第二線治療申請結果":
  if (
    "初次申請" and 
    "規則1=化學療法合併使用" and
    "規則2=未曾接受過Bevacizumab治療" and
    "規則3=RAS基因沒有突變" and
    "規則4=轉移性大腸或直腸癌病人的第二線治療" and
    "規則1=每次申請事前審查之療程以12週為限" and  
    "規則2=使用總療程以24週為上限" and
    "規則3-3=限5mg/kg每兩週一次(weight*5mg)"
  )
  then '✓通過：初次使用－大腸直腸癌 Bevacizumab 第二線用藥申請'
  else if (
    "續用申請" and
    "規則1=再次申請必須提出客觀證據（如：RECIST criteria）證實無惡化" and
    "規則1=每次申請事前審查之療程以12週為限" and  
    "規則2=使用總療程以24週為上限" and
    "規則3-3=限5mg/kg每兩週一次(weight*5mg)"
  )
  then '✓通過：續用－大腸直腸癌 Bevacizumab 第二線用藥申請'
  else if "初次申請"
  then '✖不通過：初次使用－大腸直腸癌 Bevacizumab 第二線用藥申請'
  else if "續用申請"
  then '✖不通過：續用－大腸直腸癌 Bevacizumab 第二線用藥申請'
  else '✖不通過：無法判定申請類型－大腸直腸癌 Bevacizumab 第二線用藥申請'


//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 大腸直腸癌之Bevacizumab(二線治療) 申請審核報告 ===\n' +
  '\n【申請類型】' + "申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 代碼或條件不符】\n' +
  (if "不符合項目_代碼或條件不符"() = '' then '無\n' else "不符合項目_代碼或條件不符"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【申請結果】\n' +
  "大腸直腸癌Bevacizumab第二線治療申請結果" +
  '\n===============================================\n'