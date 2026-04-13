//高復發風險乳癌_Olaparib給付規定
library BCOlaparibRule2 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include BCCodeConcept version '1.0.0' called CodeConcept

include BCReusable version '1.0.0' called Reusable

context Patient



//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/
//條件1:早期乳癌

define "ICD代碼檢核_布林值": Reusable."ICD-10使用C50"

define "醫令類別為1_布林值":Reusable."醫令類別為1"

//條件1:轉移性乳癌
//條件1-1
define "規則1-1-1=3個月內影像報告":
Reusable."HasRecentImageReport"("本次申請起始日期", 90)


//條件1-3
define "規則1-1-3=癌症分期分數或結果為M=0":
  Reusable."癌症分期分數或結果為M=0"

//條件1-4(檢查報告)
define "規則1-1-4=3個月內有檢查報告":
Reusable."HasRecentMolecularReport"("本次申請起始日期", 90)

//條件1-5
define "規則1-1-5=Olaparib申請":
  Reusable."醫令類別為1" 
  and exists (        
    [MedicationRequest] MRPlan
    where MRPlan.intent = 'plan'
      and exists (
        MRPlan.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
          and Cdg.code in CodeConcept.L01XK01
      )
  )

define "規則1-1=早期乳癌":
  "ICD代碼檢核_布林值" 
  and "醫令類別為1_布林值" 
  and "規則1-1-5=Olaparib申請"
  and "規則1-1-3=癌症分期分數或結果為M=0"
  and ("規則1-1-1=3個月內影像報告" or "規則1-1-4=3個月內有檢查報告")


//條件2:成年
define "規則1-2=成年": 
  exists (
    [Claim] C
    where C.created is not null
    and AgeInDaysAt(C.created) >= 18
  )


//條件3:遺傳性 BRCA1/2(germline BRCA1/2)突變
define "規則1-3=遺傳性 BRCA1/2(germline BRCA1/2)突變":
  exists (
    [Observation] OBs
      where exists (
        OBs.category C
          where exists (
            C.coding Cdg
              where Cdg in CodeConcept.NHIPASSupportingInfoType
                and Cdg.code = 'tests'
          )
      )
      and exists (
        OBs.code.coding Cdg
          where Cdg in CodeConcept.LOINC
            and Cdg.code in CodeConcept.BRCA1or2
      )
      and OBs.value is string
      and Matches(OBs.value as string, '(?i).*(Positive|Pathogenic|Likely Pathogenic).*')
  )


//條件4:HER2陰性
define "規則1-4=檢驗檢查-HER2陰性":
  Reusable."HasHER2NegativeTest"

define "規則1-4=基因檢測-HER2陰性":
  Reusable."HasHER2NegativeGene"

define "規則1-4=HER2陰性":
  Reusable."HasHER2Negative"


//條件5

//藥物條件
//前導性化療起始日早於此次申請藥物起始日
define "前導性化療早於本品申請起始日":
  Reusable."醫令類別為1" 
  and exists (
    [MedicationRequest] MRApply
    where MRApply.intent = 'plan'
    and exists (
      MRApply.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
      and Cdg.code in CodeConcept.L01XK01
    )
    and MRApply.dosageInstruction[0].timing.repeat.bounds is Period
    and (start of (MRApply.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
    and (end of (MRApply.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
    and exists (
      [MedicationRequest] MRChemo
      where MRChemo.intent = 'order'
      and exists (
        MRChemo.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept."前導性化療"
      )
      and Reusable."HasValidTiming"(MRChemo)
      and (end of (MRChemo.dosageInstruction[0].timing.repeat.bounds as Period)) < (start of (MRApply.dosageInstruction[0].timing.repeat.bounds as Period))
    )
  )

//影像報告日期早於此次申請藥物起始日
define "影像報告日期早於此次申請藥物起始日":
  Reusable."醫令類別為1" 
  and exists (
    [MedicationRequest] MRApply
    where MRApply.intent = 'plan'
    and exists (
      MRApply.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
      and Cdg.code in CodeConcept.L01XK01
    )
    and MRApply.dosageInstruction[0].timing.repeat.bounds is Period
    and (start of (MRApply.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
    and (end of (MRApply.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
    and exists (
      [DiagnosticReport] O
      where exists (
        O.code.coding Cdg
        where (
          Cdg in CodeConcept.ICD10PCS2023Image
          or Cdg in CodeConcept.ICD10PCS2014Image
        )
        and Cdg.code in CodeConcept.ProcedureCodes
      )
      and O.effective is not null
      and FHIRHelpers.ToDateTime(O.effective) <= FHIRHelpers.ToDateTime((MRApply.dosageInstruction[0].timing.repeat.bounds as Period).start)
    )
  )


//條件5-2:三陰性乳癌
//條件5-2-1:ER陰性
define "條件5-2-1=檢驗檢查-ER陰性":
  Reusable."HasTestObservationWithInterpretationAndValuePattern"(CodeConcept.MolecularER, { 'NEG' }, '(?i).*([-−]|0|陰性|negative).*')

define "條件5-2-1=基因檢測-ER陰性":
  Reusable."HasMarkerNegativeGene"(CodeConcept.MolecularER)

define "條件5-2-1=ER陰性":
  Reusable."HasMarkerNegativeWithGeneLoinc"(CodeConcept.MolecularER)

//條件5-2-2:PR陰性
define "條件5-2-2=檢驗檢查-PR陰性":
  Reusable."HasTestObservationWithInterpretationAndValuePattern"(CodeConcept.MolecularPR, { 'NEG' }, '(?i).*([-−]|0|陰性|negative).*')

define "條件5-2-2=基因檢測-PR陰性":
  Reusable."HasMarkerNegativeGene"(CodeConcept.MolecularPR)

define "條件5-2-2=PR陰性":
  Reusable."HasMarkerNegativeWithGeneLoinc"(CodeConcept.MolecularPR)


//條件5-2-3:針對曾接受前導性化療的病人，須符合於乳房和/或手術切除的淋巴結中發現有殘餘的侵襲性癌症(non-pCR)(病摘或病理報告結果須至少一項符合)
define "條件5-2-3=病摘或病理報告結果其一符合non-pCR":
  exists (
    [DiagnosticReport] O2
    where exists (
        O2.code.coding Cdg
        where Cdg in CodeConcept.LOINC
          and Cdg.code = '66110-8'
      )
      and O2.effective is not null
      and FHIRHelpers.ToDateTime(O2.effective) >= "本次申請起始日期" - 90 days
      and FHIRHelpers.ToDateTime(O2.effective) <= "本次申請起始日期"
      and O2.conclusion is not null
      and Matches(O2.conclusion, '(?i).*(乳房和/或手術切除的淋巴結中發現有殘餘的侵襲性癌症\(non-pCR\)\+).*')
  )
  or exists (
    [Claim] C
    where exists (
        C.diagnosis D
        where exists (
            D.type.text T
            where Matches(T.value, '(?i).*(乳房和/或手術切除的淋巴結中發現有殘餘的侵襲性癌症\(non-pCR\)\+).*')
          )
      )
  )


//條件5-2-4:針對曾接受手術且接續術後輔助性化療的病人，須具有腋窩淋巴結陽性(≧pN1)，或腋窩淋巴結陰性(pN0)且原發性病理腫瘤大小≧2公分(≧pT2)(病摘或病理報告結果須至少一項符合)
define "條件5-2-4=病摘或病理報告結果其一符合≧pN1且≧pT2":  
  exists (
    [DiagnosticReport] O2
    where exists (
        O2.code.coding Cdg
        where Cdg in CodeConcept.LOINC
          and Cdg.code = '66110-8'
      )
      and O2.effective is not null
      and FHIRHelpers.ToDateTime(O2.effective) >= "本次申請起始日期" - 90 days
      and FHIRHelpers.ToDateTime(O2.effective) <= "本次申請起始日期"
      and O2.conclusion is not null
      and Matches(O2.conclusion, '(?i).*具有腋窩淋巴結陽性\(≧pN1\)，或腋窩淋巴結陰性\(pN0\)且原發性病理腫瘤大小≧2公分\(≧pT2\).*')
  )
  or exists (
    [Claim] C
    where exists (
        C.diagnosis D
        where exists (
            D.type.text T
            where Matches(T.value, '(?i).*具有腋窩淋巴結陽性\(≧pN1\)，或腋窩淋巴結陰性\(pN0\)且原發性病理腫瘤大小≧2公分\(≧pT2\).*')
          )
      )
  )


define "條件5-2-3":
"條件5-2-3=病摘或病理報告結果其一符合non-pCR"
  and "前導性化療早於本品申請起始日"

define "條件5-2-4":
"條件5-2-4=病摘或病理報告結果其一符合≧pN1且≧pT2"
  and "前導性化療早於本品申請起始日"
  and "影像報告日期早於此次申請藥物起始日"

define "條件5-2":
  if ("條件5-2-1=ER陰性" and "條件5-2-2=PR陰性")
    then ("條件5-2-3" or "條件5-2-4")
  else false


//條件5-3:HR陽性且HER2陰性乳癌
//條件5-3-1:ER陽性
define "條件5-3-1=檢驗檢查-ER陽性":
  exists (
    [Observation] OBs
      where exists (
        OBs.category C
          where exists (
            C.coding Cdg
              where Cdg in CodeConcept.NHIPASSupportingInfoType
                and Cdg.code = 'tests'
          )
      )
      and exists (
        OBs.code.coding Cdg
          where Cdg in CodeConcept.LOINC
            and Cdg.code in CodeConcept.MolecularER
      )
      and exists (
        OBs.interpretation.coding INT
          where INT in CodeConcept.InterpretationCodes
            and INT.code in {'POS'}
      )
      and OBs.value is string
      and Matches(OBs.value as string, '(?i).*(\\+|陽性|positive).*')
  )

define "條件5-3-1=基因檢測-ER陽性":
  exists (
    [Observation] OBs
      where exists (
        OBs.category C
          where exists (
            C.coding Cdg
              where Cdg in CodeConcept.NHIPASSupportingInfoType
                and Cdg.code = 'geneInfo'
          )
      )
    and exists (
      OBs.code.coding Cdg
      where Cdg in CodeConcept.LOINC
      and Cdg.code = '69548-6'
    )
    and exists (
      OBs.component Comp
        where exists (
          Comp.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept.MolecularER
        )
        and Comp.value is Quantity
        and (Comp.value as Quantity).value > 30
        and (Comp.value as Quantity).comparator = '>'
        and (Comp.value as Quantity).unit = '%'
        and exists (
          Comp.interpretation I
            where Matches(I.text, '(?i).*(\\+|陽性|positive).*')
        )
    )
  )

define "條件5-3-1=ER陽性":
  "條件5-3-1=檢驗檢查-ER陽性" or "條件5-3-1=基因檢測-ER陽性"

//條件5-3-2:PR陽性
define "條件5-3-2=檢驗檢查-PR陽性":
  exists (
    [Observation] OBs
      where exists (
        OBs.category C
          where exists (
            C.coding Cdg
              where Cdg in CodeConcept.NHIPASSupportingInfoType
                and Cdg.code = 'tests'
          )
      )
      and exists (
        OBs.code.coding Cdg
          where Cdg in CodeConcept.LOINC
            and Cdg.code in CodeConcept.MolecularPR
      )
      and exists (
        OBs.interpretation.coding INT
          where INT in CodeConcept.InterpretationCodes
            and INT.code in {'POS'}
      )
      and OBs.value is string
      and Matches(OBs.value as string, '(?i).*(\\+|陽性|positive).*')
  )

define "條件5-3-2=基因檢測-PR陽性":
  exists (
    [Observation] OBs
      where exists (
        OBs.category C
          where exists (
            C.coding Cdg
              where Cdg in CodeConcept.NHIPASSupportingInfoType
                and Cdg.code = 'geneInfo'
          )
      )
    and exists (
      OBs.code.coding Cdg
      where Cdg in CodeConcept.LOINC
      and Cdg.code = '69548-6'
    )
    and exists (
      OBs.component Comp
        where exists (
          Comp.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept.MolecularPR
        )
             and exists (
        OBs.interpretation.coding INT
          where INT in CodeConcept.InterpretationCodes
            and INT.code in {'POS'}
      )
      and OBs.value is string
      and Matches(OBs.value as string, '(?i).*(\\+|陽性|positive).*')
        )
          )


define "條件5-3-2=PR陽性":
  "條件5-3-2=檢驗檢查-PR陽性" or "條件5-3-2=基因檢測-PR陽性"


//條件5-3-3:曾接受前導性化療的病人，須為 non-pCR(病摘或病理報告結果須至少一項符合)
define "條件5-3-3=曾接受前導性化療的病人，須為non-pCR":
  exists (
    [DiagnosticReport] O2
    where exists (
        O2.code.coding Cdg
        where Cdg in CodeConcept.LOINC
          and Cdg.code = '66110-8'
      )
      and O2.effective is not null
      and FHIRHelpers.ToDateTime(O2.effective) >= "本次申請起始日期" - 90 days
      and FHIRHelpers.ToDateTime(O2.effective) <= "本次申請起始日期"
      and O2.conclusion is not null
      and Matches(O2.conclusion, '(?i).*non-pCR.*')
  )
  or exists (
    [Claim] C
    where exists (
        C.diagnosis D
        where exists (
            D.type.text T
            where Matches(T.value, '(?i).*non-pCR.*')
          )
      )
  )


//條件5-3-4:曾接受手術且接續術後輔助性化療的病人，須具有4個以上經病理學證實的陽性淋巴結(病摘或病理報告結果須至少一項符合)
define "條件5-3-4=曾接受手術且接續術後輔助性化療的病人，須具有4個以上經病理學證實的陽性淋巴結":  
  exists (
    [DiagnosticReport] O2
    where exists (
        O2.code.coding Cdg
        where Cdg in CodeConcept.LOINC
          and Cdg.code = '66110-8'
      )
      and O2.effective is not null
      and FHIRHelpers.ToDateTime(O2.effective) >= "本次申請起始日期" - 90 days
      and FHIRHelpers.ToDateTime(O2.effective) <= "本次申請起始日期"
      and O2.conclusion is not null
      and Matches(O2.conclusion, '(?i).*須具有4個以上經病理學證實的陽性淋巴結.*')
  )
  or exists (
    [Claim] C
    where exists (
        C.diagnosis D
        where exists (
            D.type.text T
            where Matches(T.value, '(?i).*須具有4個以上經病理學證實的陽性淋巴結.*')
          )
      )
  )

define "條件5-3-3":
"條件5-3-3=曾接受前導性化療的病人，須為non-pCR"
  and "前導性化療早於本品申請起始日"

define "條件5-3-4":
"條件5-3-4=曾接受手術且接續術後輔助性化療的病人，須具有4個以上經病理學證實的陽性淋巴結"
  and "前導性化療早於本品申請起始日"
  and "影像報告日期早於此次申請藥物起始日"

define "條件5-3":
  if ("條件5-3-1=ER陽性" and "條件5-3-2=PR陽性")
    then ("條件5-3-3" or "條件5-3-4")
  else false

define "規則1-5=高復發風險":
"條件5-2" or "條件5-3"


//條件6:曾接受前導性化療或術後輔助性化療(至少6個週期、須含有anthracyclines 類藥物、taxane 類藥物，或兩者的複方；亦允許含鉑化療)
define "規則1-6=曾接受前導性化療或術後輔助性化療，且至少6個週期":
  Reusable."醫令類別為1" 
  and exists (
    [MedicationRequest] MRApply
    where MRApply.intent = 'plan'
    and exists (
        MRApply.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.L01XK01
    )
    and MRApply.dosageInstruction[0].timing.repeat.bounds is Period
    and (start of (MRApply.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
    and (end of (MRApply.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
    and Count(
        [MedicationRequest] MRChemo
        where MRChemo.intent = 'order'
        and exists (
            MRChemo.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
            and Cdg.code in CodeConcept."前導性化療或術後輔助性化療"
        )
        and Reusable."HasValidTiming"(MRChemo)
        and (end of (MRChemo.dosageInstruction[0].timing.repeat.bounds as Period)) < (start of (MRApply.dosageInstruction[0].timing.repeat.bounds as Period))
    ) >= 6
  )

//條件7:須在最後一次治療(包括手術、化療或放療)完成後的12週內使用olaparib(手術、化療或放療須至少一項符合)
define "規則1-7=須在最後一次治療完成後的12週內使用olaparib":
  Reusable."醫令類別為1"
  and exists (
    [MedicationRequest] MRApply
    where MRApply.intent = 'plan'
    and exists (
      MRApply.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.L01XK01
    )
    and MRApply.dosageInstruction[0].timing.repeat.bounds is Period
    and (start of (MRApply.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
    and (end of (MRApply.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
    and exists (
      [MedicationRequest] MRChemo
      where MRChemo.intent = 'order'
        and exists (
          MRChemo.medication.coding Cdg
          where Cdg in CodeConcept.NHIMedication
            and Cdg.code in CodeConcept."手術或化療或放療"
        )
        and Reusable."HasValidTiming"(MRChemo)
        and (end of (MRChemo.dosageInstruction[0].timing.repeat.bounds as Period)) < (start of (MRApply.dosageInstruction[0].timing.repeat.bounds as Period))
        and (end of (MRChemo.dosageInstruction[0].timing.repeat.bounds as Period)) >= ((start of (MRApply.dosageInstruction[0].timing.repeat.bounds as Period)) - 12 weeks)
        and not exists (
          [MedicationRequest] MRChemoLater
          where MRChemoLater.intent = 'order'
            and exists (
              MRChemoLater.medication.coding Cdg2
              where Cdg2 in CodeConcept.NHIMedication
                and Cdg2.code in CodeConcept."手術或化療或放療"
            )
            and Reusable."HasValidTiming"(MRChemoLater)
            and (end of (MRChemoLater.dosageInstruction[0].timing.repeat.bounds as Period)) > (end of (MRChemo.dosageInstruction[0].timing.repeat.bounds as Period))
            and (end of (MRChemoLater.dosageInstruction[0].timing.repeat.bounds as Period)) < (start of (MRApply.dosageInstruction[0].timing.repeat.bounds as Period))
        )
    )
    and exists (
      [DiagnosticReport] O
      where exists (
        O.code.coding Cdg
        where (
          Cdg in CodeConcept.ICD10PCS2023Image
          or Cdg in CodeConcept.ICD10PCS2014Image
        )
        and Cdg.code in CodeConcept.ProcedureCodes
      )
      and O.effective is not null
      and FHIRHelpers.ToDateTime(O.effective) <= FHIRHelpers.ToDateTime((MRApply.dosageInstruction[0].timing.repeat.bounds as Period).start)
      and FHIRHelpers.ToDateTime(O.effective) >= (FHIRHelpers.ToDateTime((MRApply.dosageInstruction[0].timing.repeat.bounds as Period).start) - 12 weeks)
    )
  )

/*規則1*/
define "規則1":
"規則1-1=早期乳癌"
and "規則1-2=成年"
and "規則1-3=遺傳性 BRCA1/2(germline BRCA1/2)突變"
and "規則1-4=HER2陰性"
and "規則1-5=高復發風險"
and "規則1-6=曾接受前導性化療或術後輔助性化療，且至少6個週期"
and "規則1-7=須在最後一次治療完成後的12週內使用olaparib"

/*規則2之條件，皆於規則1中已涵蓋*/

//主要規定一
define "主要規定一": "規則1"

//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.L01XK01)

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

//影像證據顯示病情有無惡化
// 取得前次治療紀錄（最近一次已完成的治療）
define "前次治療紀錄":
  Reusable."LatestCompletedMedicationOrderBefore"(CodeConcept.L01XK01, "本次申請起始日期")

// 前次用藥開始日期
define "前次用藥開始日期":
  Reusable."GetStartTime"("前次治療紀錄")

// 條件1:影像證據顯示病情有無惡化
define "規則1=影像證據顯示病情有無惡化":
  Reusable."HasImageReportBetweenPreviousTreatmentAndCurrentApply"(CodeConcept.L01XK01)


// 主要規定二
define "主要規定二":
Reusable."續用註記為2"
and "規則1=影像證據顯示病情有無惡化"


//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
//每次申請之療程以3個月為限
define "規則1=每次申請之療程以3個月為限":
  Reusable."HasMedicationPlanDurationWithin"(CodeConcept.L01XK01, 84)

/*規則2*/
define "規則2=依藥品仿單記載以1年為上限":
  Reusable."HasMedicationTotalDurationWithin"(CodeConcept.L01XK01, 365)

/*規則3:用於術後輔助治療，olaparib 與 pembrolizumab 僅能擇一給付。(由於此處皆為術後輔助治療，故使用過pembrolizumab者不得使用本品)*/
define "規則3=Olaparib、pembrolizumab僅得擇一使用":
  not (
    Reusable."HasMedicationUse"(CodeConcept.L01XK01)
    and Reusable."HasMedicationUse"(CodeConcept.L01FF02)
  )


/*規則4*/
define "規則4=Olaparib每日最多使用4粒":
  Reusable."HasDailyDoseAtMost"(CodeConcept.L01XK01, 4.0, '{tbl}', 'QD')

// 主要規定三
define "主要規定三":
"規則1=每次申請之療程以3個月為限"
and "規則2=依藥品仿單記載以1年為上限"
and "規則3=Olaparib、pembrolizumab僅得擇一使用"
and "規則4=Olaparib每日最多使用4粒"



//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and (
    "規則1-1=早期乳癌" or 
    "規則1-2=成年" or 
    "規則1-3=遺傳性 BRCA1/2(germline BRCA1/2)突變" or 
    "規則1-4=HER2陰性" or 
    "規則1-5=高復發風險" or 
    "規則1-6=曾接受前導性化療或術後輔助性化療，且至少6個週期" or 
    "規則1-7=須在最後一次治療完成後的12週內使用olaparib"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "ICD代碼檢核_布林值" 
           then '● 規則1-1-0：ICD代碼為C50\n' else '') +
         (if "規則1-1-1=3個月內影像報告" 
           then '● 規則1-1-1：3個月內影像報告\n' else '') +
         (if "規則1-1-3=癌症分期分數或結果為M=0" 
           then '● 規則1-1-3：癌症分期分數或結果為M=0（早期）\n' else '') +
         (if "規則1-1-4=3個月內有檢查報告" 
           then '● 規則1-1-4：3個月內有檢查報告\n' else '') +
         (if "規則1-1-5=Olaparib申請" 
           then '● 規則1-1-5：Olaparib申請\n' else '') +
         (if "規則1-2=成年" 
           then '● 規則1-2：成年（≥18歲）\n' else '') +
         (if "規則1-3=遺傳性 BRCA1/2(germline BRCA1/2)突變" 
           then '● 規則1-3：遺傳性BRCA1/2（germline BRCA1/2）突變\n' else '') +
         (if "規則1-4=HER2陰性" 
           then '● 規則1-4：HER2陰性\n' else '') +
         (if "條件5-2-1=ER陰性" 
           then '● 規則1-5-2-1：ER陰性\n' else '') +
         (if "條件5-2-2=PR陰性" 
           then '● 規則1-5-2-2：PR陰性\n' else '') +
         (if "條件5-2-3=病摘或病理報告結果其一符合non-pCR" 
           then '● 規則1-5-2-3：病摘或病理報告結果符合non-pCR\n' else '') +
         (if "條件5-2-4=病摘或病理報告結果其一符合≧pN1且≧pT2" 
           then '● 規則1-5-2-4：病摘或病理報告結果符合≧pN1且≧pT2\n' else '') +
         (if "條件5-3-1=ER陽性" 
           then '● 規則1-5-3-1：ER陽性\n' else '') +
         (if "條件5-3-2=PR陽性" 
           then '● 規則1-5-3-2：PR陽性\n' else '') +
         (if "條件5-3-3=曾接受前導性化療的病人，須為non-pCR" 
           then '● 規則1-5-3-3：曾接受前導性化療的病人，須為non-pCR\n' else '') +
         (if "條件5-3-4=曾接受手術且接續術後輔助性化療的病人，須具有4個以上經病理學證實的陽性淋巴結" 
           then '● 規則1-5-3-4：具有4個以上經病理學證實的陽性淋巴結\n' else '') +
         (if "規則1-6=曾接受前導性化療或術後輔助性化療，且至少6個週期" 
           then '● 規則1-6：曾接受前導性化療或術後輔助性化療，且至少6個週期\n' else '') +
         (if "規則1-7=須在最後一次治療完成後的12週內使用olaparib" 
           then '● 規則1-7：於最後一次治療完成後的12週內使用olaparib\n' else '') +
         '\n'
    else '') +
  
  // 主要規定二：續用條件
  (if Reusable."續用申請" and "規則1=影像證據顯示病情有無惡化"
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '● 續用規則1：已檢附前次治療後影像學報告，確認無惡化\n' +
         '\n'
    else '') +
  
  // 主要規定三：藥品使用規則
  (if "規則1=每次申請之療程以3個月為限" or "規則2=依藥品仿單記載以1年為上限" or "規則3=Olaparib、pembrolizumab僅得擇一使用" or "規則4=Olaparib每日最多使用4粒"
    then '<主要規定三：藥品使用規則>\n' +
         (if "規則1=每次申請之療程以3個月為限" 
           then '● 規則3-1：每次申請之療程≤3個月（84天）\n' else '') +
         (if "規則2=依藥品仿單記載以1年為上限" 
           then '● 規則3-2：使用總療程≤1年（365天）\n' else '') +
         (if "規則3=Olaparib、pembrolizumab僅得擇一使用" 
           then '● 規則3-3：Olaparib與pembrolizumab僅得擇一使用\n' else '') +
         (if "規則4=Olaparib每日最多使用4粒" 
           then '● 規則3-4：每日劑量≤4粒\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 代碼或條件不符
//============================================

define function "不符合項目_代碼或條件不符"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if Reusable."初次申請" and (
    not "ICD代碼檢核_布林值" or 
    not "規則1-1-3=癌症分期分數或結果為M=0" or 
    not "規則1-2=成年"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "ICD代碼檢核_布林值" 
           then '▲ 規則1-1-0：主要疾病之ICD代碼未使用C50\n' else '') +
         (if not "規則1-1-3=癌症分期分數或結果為M=0" 
           then '▲ 規則1-1-3：癌症分期分數或結果不為M=0（非早期）\n' else '') +
         (if not "規則1-2=成年" 
           then '▲ 規則1-2：非成年患者（<18歲）\n' else '') +
         '\n'
    else '') +
  
  // 主要規定三：藥品使用規則 - 代碼條件不符
  (if not "規則1=每次申請之療程以3個月為限" or not "規則2=依藥品仿單記載以1年為上限" or not "規則3=Olaparib、pembrolizumab僅得擇一使用" or not "規則4=Olaparib每日最多使用4粒"
    then '<主要規定三：藥品使用規則>\n' +
         (if not "規則1=每次申請之療程以3個月為限" 
           then '▲ 規則3-1：每次申請之療程超過3個月（84天）\n' else '') +
         (if not "規則2=依藥品仿單記載以1年為上限" 
           then '▲ 規則3-2：使用總療程超過1年（365天）\n' else '') +
         (if not "規則3=Olaparib、pembrolizumab僅得擇一使用" 
           then '▲ 規則3-3：同時使用Olaparib與pembrolizumab\n' else '') +
         (if not "規則4=Olaparib每日最多使用4粒" 
           then '▲ 規則3-4：每日劑量超過4粒\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
    not "規則1-1-5=Olaparib申請" or 
    not ("規則1-1-1=3個月內影像報告" or "規則1-1-4=3個月內有檢查報告") or 
    not "規則1-3=遺傳性 BRCA1/2(germline BRCA1/2)突變" or 
    not "規則1-4=HER2陰性" or 
    not "規則1-5=高復發風險" or 
    not "規則1-6=曾接受前導性化療或術後輔助性化療，且至少6個週期" or 
    not "規則1-7=須在最後一次治療完成後的12週內使用olaparib"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "規則1-1-5=Olaparib申請" 
           then '▲ 規則1-1-5：未申請Olaparib\n' else '') +
         (if not ("規則1-1-1=3個月內影像報告" or "規則1-1-4=3個月內有檢查報告") 
           then '▲ 規則1-1-1/1-1-4：未提供3個月內影像報告或檢查報告\n' else '') +
         (if not "規則1-3=遺傳性 BRCA1/2(germline BRCA1/2)突變" 
           then '▲ 規則1-3：未提供遺傳性BRCA1/2（germline BRCA1/2）突變檢測資料\n' else '') +
         (if not "規則1-4=HER2陰性" 
           then '▲ 規則1-4：未提供HER2檢測資料或HER2非陰性\n' else '') +
         (if not "規則1-5=高復發風險" 
           then '▲ 規則1-5：未符合高復發風險條件（需符合三陰性或HR陽性HER2陰性之相關標準）\n' +
                (if not "條件5-2" and not "條件5-3"
                  then '  - 未符合三陰性乳癌或HR陽性且HER2陰性乳癌之高復發風險條件\n' else '')
           else '') +
         (if not "規則1-6=曾接受前導性化療或術後輔助性化療，且至少6個週期" 
           then '▲ 規則1-6：未提供前導性化療或術後輔助性化療紀錄，或未達至少6個週期\n' else '') +
         (if not "規則1-7=須在最後一次治療完成後的12週內使用olaparib" 
           then '▲ 規則1-7：未於最後一次治療完成後的12週內使用olaparib\n' else '') +
         '\n'
    else '') +
  
  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and not "規則1=影像證據顯示病情有無惡化"
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '▲ 續用規則1：未提供前次治療後影像學報告或顯示疾病惡化\n' +
         '\n'
    else '')

//============================================
// 審核結果
//============================================

define "乳癌Olaparib申請結果_布林":
  case
    when Reusable."初次申請" then (
      "規則1-1=早期乳癌" and
      "規則1-2=成年" and
      "規則1-3=遺傳性 BRCA1/2(germline BRCA1/2)突變" and
      "規則1-4=HER2陰性" and
      "規則1-5=高復發風險" and
      "規則1-6=曾接受前導性化療或術後輔助性化療，且至少6個週期" and
      "規則1-7=須在最後一次治療完成後的12週內使用olaparib" and
      "規則1=每次申請之療程以3個月為限" and
      "規則2=依藥品仿單記載以1年為上限" and
      "規則3=Olaparib、pembrolizumab僅得擇一使用" and
      "規則4=Olaparib每日最多使用4粒"
    )
    when Reusable."續用申請" then (
      "規則1=影像證據顯示病情有無惡化" and
      "規則1=每次申請之療程以3個月為限" and
      "規則2=依藥品仿單記載以1年為上限" and
      "規則3=Olaparib、pembrolizumab僅得擇一使用" and
      "規則4=Olaparib每日最多使用4粒"
    )
    else false
  end

define "乳癌Olaparib申請之CQL檢核結果":
  if (
    Reusable."初次申請" and 
    "規則1-1=早期乳癌" and
    "規則1-2=成年" and
    "規則1-3=遺傳性 BRCA1/2(germline BRCA1/2)突變" and
    "規則1-4=HER2陰性" and
    "規則1-5=高復發風險" and
    "規則1-6=曾接受前導性化療或術後輔助性化療，且至少6個週期" and
    "規則1-7=須在最後一次治療完成後的12週內使用olaparib" and
    "規則1=每次申請之療程以3個月為限" and
    "規則2=依藥品仿單記載以1年為上限" and
    "規則3=Olaparib、pembrolizumab僅得擇一使用" and
    "規則4=Olaparib每日最多使用4粒"
  )
  then '✓通過：初次使用－高復發風險之早期乳癌 Olaparib 用藥申請'

  else if (
    Reusable."續用申請" and
    "規則1=影像證據顯示病情有無惡化" and
    "規則1=每次申請之療程以3個月為限" and
    "規則2=依藥品仿單記載以1年為上限" and
    "規則3=Olaparib、pembrolizumab僅得擇一使用" and
    "規則4=Olaparib每日最多使用4粒"
  )
  then '✓通過：續用－高復發風險之早期乳癌 Olaparib 用藥申請'
  
  else if Reusable."初次申請"
  then '✖不通過：初次使用－高復發風險之早期乳癌 Olaparib 用藥申請'
  
  else if Reusable."續用申請"
  then '✖不通過：續用－高復發風險之早期乳癌 Olaparib 用藥申請'
  
  else '✖不通過：無法判定申請類型－高復發風險之早期乳癌 Olaparib 用藥申請'

//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 高復發風險之早期乳癌 Olaparib 申請審核報告 ===\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 代碼或條件不符】\n' +
  (if "不符合項目_代碼或條件不符"() = '' then '無\n' else "不符合項目_代碼或條件不符"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【申請結果】\n' +
  "乳癌Olaparib申請之CQL檢核結果" +
  '\n===============================================\n'
