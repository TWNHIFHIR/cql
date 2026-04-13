//乳癌_Trastuzumab給付規定
library BCTrastuzumabRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include BCCodeConcept version '1.0.0' called CodeConcept

include BCReusable version '1.0.0' called Reusable

context Patient



//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/

define "手術日期(opdate)":
  Max(
    flatten(
      [Claim] C
        return (
          C.procedure Proc
            where Proc.date is not null
            return FHIRHelpers.ToDateTime(Proc.date)
        )
    )
  )

define "手術(或其他處置)項目":
  exists (
  [Claim] C
    where exists (
      C.procedure Proc
        where exists (
          ((Proc.procedure as FHIR.CodeableConcept).coding) Cdg
            where Cdg is not null
              and (Cdg.code in CodeConcept."ICD10PCS2023Image"
                or Cdg.code in CodeConcept."ICD10PCS2014Image")
              and Cdg.code in CodeConcept."ProcedureCodes"
        )
    )
  )

//條件1:外科手術前後、化學療法(術前輔助治療或輔助治療)治療後

//條件1-1-1
define "條件1-1-1=病摘描述本藥品使用在外科手術前":
  exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*本藥品使用在外科手術前.*')
            )
        )
    )


//條件1-1-2
define "條件1-1-2=外科手術後":
  exists (
    [MedicationRequest] MR
      where MR.intent = 'plan'
        and Reusable."HasValidTiming"(MR)
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and Cdg.code in CodeConcept.L01FD01
        )
        and Reusable."醫令類別為1"
        and MR.dosageInstruction[0].timing.repeat.bounds is Period
        and (start of (MR.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
        and (start of (MR.dosageInstruction[0].timing.repeat.bounds as Period)) > "手術日期(opdate)"
        and "手術(或其他處置)項目"
  )


//條件1-2
define "條件1-2=化學療法(術前輔助治療或輔助治療)治療後":
  Reusable."HasPriorMedicationUse"(CodeConcept.L01FD01, CodeConcept."併用化學治療法")
  and Reusable."醫令類別為1"

define "條件1-1=外科手術前後":
  (not "條件1-1-1=病摘描述本藥品使用在外科手術前" 
        or "條件1-1-2=外科手術後")
  or "條件1-2=化學療法(術前輔助治療或輔助治療)治療後"


//條件2-1
define "條件2-1=檢驗檢查-HER2過度表現(IHC3+或FISH+)":
  Reusable."HasHER2OverexpressionTest"

define "條件2-1=基因檢測-HER2過度表現(IHC3+或FISH+)":
  Reusable."HasHER2OverexpressionGene"

define "條件2-1=HER2過度表現(IHC3+或FISH+)":
  "條件2-1=檢驗檢查-HER2過度表現(IHC3+或FISH+)"
  or "條件2-1=基因檢測-HER2過度表現(IHC3+或FISH+)"


//條件2-2
define "條件2-2=檢驗檢查-ER陰性":
  Reusable."HasMarkerNegativeWithGeneLoincTest"(CodeConcept.MolecularER)

define "條件2-2=基因檢測-ER陰性":
  Reusable."HasMarkerNegativeWithGeneLoincGene"(CodeConcept.MolecularER)

define "條件2-2=ER陰性":
  "條件2-2=檢驗檢查-ER陰性" or "條件2-2=基因檢測-ER陰性"


//條件2-3
define "條件2-3=腫瘤大於2公分。須經乳房超音波或乳房X光攝影或核磁共振診斷":
  exists (
    [DiagnosticReport] O
    where exists (
      O.code.coding Cdg
      where (
        Cdg in CodeConcept.ICD10PCS2023Image
        or Cdg in CodeConcept.ICD10PCS2014Image
      )
      and Cdg.code in CodeConcept.ProcedureCodes2
    )
    and O.effective is not null
    and FHIRHelpers.ToDateTime(O.effective) >= "本次申請起始日期" - 90 days
    and FHIRHelpers.ToDateTime(O.effective) <= "本次申請起始日期"
  ) 


//條件2-4
define "ICD代碼檢核_布林值": Reusable."ICD-10使用C50"

define "醫令類別為1_布林值":Reusable."醫令類別為1"

//條件2-4-1
define "條件2-4-1=3個月內影像報告":
Reusable."HasRecentImageReport"("本次申請起始日期", 90)


//條件2-4-2
define "條件2-4-2=癌症分期分數或結果為N=0":
  Count(
    [Observation] O
    where exists (
    O.code.coding Cdg
    where Cdg.code = '399390009'
    and Cdg in CodeConcept.SNOMED
    )
    and O.value is not null
    and O.value is FHIR.string
    and Matches((O.value as FHIR.string).value, '.*N[0].*')
  ) > 0

//條件2-4-3(檢查報告)
define "條件2-4-3=3個月內有檢查報告":
Reusable."HasRecentMolecularReport"("本次申請起始日期", 90)

define "條件2-4=且未發生腋下淋巴結轉移之早期乳癌患者，作為輔助性治療用藥":
  "ICD代碼檢核_布林值" 
  and "醫令類別為1_布林值" 
  and "條件2-4-2=癌症分期分數或結果為N=0"
  and ("條件2-4-1=3個月內影像報告" or "條件2-4-3=3個月內有檢查報告")


//條件2-5:依下列條件之一使用
//條件2-5-1
define "條件2-5-1=經外科手術後達病理上完全緩解者(pCR)":
  exists (
    [DiagnosticReport] O2
    where exists (
        O2.code.coding Cdg
        where Cdg in CodeConcept.LOINC
          and Cdg.code = '66110-8'
      )
      and O2.effective is not null
      and FHIRHelpers.ToDateTime(O2.effective) > "手術日期(opdate)"
      and O2.conclusion is not null
      and Matches(O2.conclusion, '(?i).*(外科手術後達病理上完全緩解\（pCR\）|pCR).*')
  )   and "手術(或其他處置)項目" 


//條件2-5-2
define "條件2-5-2=若外科手術後無法達病理上緩解(non-pCR)":
  exists (
    [DiagnosticReport] O2
    where exists (
        O2.code.coding Cdg
        where Cdg in CodeConcept.LOINC
          and Cdg.code = '66110-8'
      )
      and O2.effective is not null
      and FHIRHelpers.ToDateTime(O2.effective) > "手術日期(opdate)"
      and FHIRHelpers.ToDateTime(O2.effective) <= "本次申請起始日期"
      and O2.conclusion is not null
      and Matches(O2.conclusion, '(?i).*(non-pCR\+).*')
  )



define "條件2-5=依下列條件之一使用":
"條件2-5-1=經外科手術後達病理上完全緩解者(pCR)" or "條件2-5-2=若外科手術後無法達病理上緩解(non-pCR)"


define "1條件2=符合下列所有條件之早期乳癌患者(限使用Ogivri、Herzuma、Eirgasun、Herceptin、Kanjinti)":
"條件2-1=HER2過度表現(IHC3+或FISH+)"
and "條件2-2=ER陰性"
and "條件2-3=腫瘤大於2公分。須經乳房超音波或乳房X光攝影或核磁共振診斷"
and "條件2-4=且未發生腋下淋巴結轉移之早期乳癌患者，作為輔助性治療用藥"
and "條件2-5=依下列條件之一使用" 

//主要規定一＝1規則1
define "主要規定一":
"條件1-1=外科手術前後" and "1條件2=符合下列所有條件之早期乳癌患者(限使用Ogivri、Herzuma、Eirgasun、Herceptin、Kanjinti)"



//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

//條件1:核准後每24週須檢附療效評估資料再次申請，若疾病有惡化情形即不應再行申請

// 本次申請紀錄（以最新一筆申請作為本次申請）
define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.L01FD01)

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

// 前次申請紀錄（本次申請之前最近一次的申請）
define "前次申請紀錄":
  Reusable."LatestMedicationPlanBefore"(CodeConcept.L01FD01, "本次申請起始日期")

// 檢查本次申請療程長度是否在24週內
define "規則1-1=每24週須再次申請並檢附療效評估資料":
  Reusable."醫令類別為1" 
  and Reusable."續用註記為2"
  and "本次申請紀錄" is not null
  and Reusable."HasMedicationPlanPeriodWithinDays"(CodeConcept.L01FD01, 168)


//條件2:疾病有惡化情形須停止使用

// 取得前次治療紀錄（最近一次已完成的治療）
define "前次治療紀錄":
  Reusable."LatestCompletedMedicationOrderBefore"(CodeConcept.L01FD01, "本次申請起始日期")

// 前次用藥開始日期
define "前次用藥開始日期":
  Reusable."GetStartTime"("前次治療紀錄")

// 規則1-2: 疾病有惡化情形須停止使用(續用須檢附前次治療後影像學報告)
define "規則1-2=疾病有惡化情形須停止使用":
  Reusable."HasImageReportBetweenPreviousTreatmentAndCurrentApply"(CodeConcept.L01FD01)

// 主要規定二
define "主要規定二":
Reusable."續用註記為2"
and Reusable."醫令類別為1"
and "本次申請紀錄" is not null
and "規則1-1=每24週須再次申請並檢附療效評估資料"
and "規則1-2=疾病有惡化情形須停止使用"


//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
//條件1:外科手術後達病理上緩解(pCR) 同 "條件2-5-1=經外科手術後達病理上完全緩解者(pCR)"


//條件2:下列i.~iii.使用於外科手術前後之總療程合併計算，依藥品仿單記載以18個療程為上限：
//i.本藥品
//ii.pertuzumab與trastuzumab（限使用Ogivri、Herzuma、Eirgasun、Herceptin、Kanjinti）併用
//iii.pertuzumab與trastuzumab皮下注射複方製劑(如Phesgo)

//三種用藥選擇合併療程計算，上限為18個療程
// 每周療程: count(MR where count=1) ≤ 18 且 sum(useEdate-useSdate) ≤ 126天
define "1條件2-1=三種用藥合併每周療程上限18個療程":
  Count(
    [MedicationRequest] MR
      where MR.intent = 'plan'
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and (Cdg.code in CodeConcept.L01FY01
                or Cdg.code in CodeConcept.L01FD01
                or Cdg.code in CodeConcept.L01FD01andL01FD02exceptKC011362B5)
        )
        and MR.dosageInstruction[0].timing.repeat.count = 1
        and Reusable."醫令類別為1"
  ) <= 18
  and Sum(
    [MedicationRequest] MR
      where MR.intent = 'plan'
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and (Cdg.code in CodeConcept.L01FY01
                or Cdg.code in CodeConcept.L01FD01
                or Cdg.code in CodeConcept.L01FD01andL01FD02exceptKC011362B5)
        )
        and MR.dosageInstruction[0].timing.repeat.count = 1
        and MR.dosageInstruction[0].timing.repeat.bounds is Period
        and (start of (MR.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
        and (end of (MR.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
      return all
        difference in days between
          FHIRHelpers.ToDateTime(
            (MR.dosageInstruction[0].timing.repeat.bounds as Period).start
          )
          and FHIRHelpers.ToDateTime(
            (MR.dosageInstruction[0].timing.repeat.bounds as Period).end
          )
  ) <= 126

// 每三周療程: 同一起始日視為同一療程，僅保留結束日最晚的代表醫令後，count ≤ 18 且 sum(useEdate-useSdate) ≤ 378天
define "1條件2-2=三種用藥合併每三周療程上限18個療程":
  // 計算三種用藥合併後的代表療程數
  Count(
    [MedicationRequest] MR
      where MR.intent = 'plan'
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and (Cdg.code in CodeConcept.L01FY01
                or Cdg.code in CodeConcept.L01FD01
                or Cdg.code in CodeConcept.L01FD01andL01FD02exceptKC011362B5)
        )
        and MR.dosageInstruction[0].timing.repeat.period = 3
        and MR.dosageInstruction[0].timing.repeat.periodUnit.value = 'wk'
        and Reusable."醫令類別為1"
        and Reusable."HasValidTiming"(MR)
        // 若同一起始日有多筆藥物，只保留結束日最晚者作為該療程代表
        and FHIRHelpers.ToDateTime(
          (MR.dosageInstruction[0].timing.repeat.bounds as Period).end
        ) =
          Max(
            [MedicationRequest] MRSameCourse
              where MRSameCourse.intent = 'plan'
                and exists (
                  MRSameCourse.medication.coding SameCdg
                    where SameCdg in CodeConcept.NHIMedication
                      and (SameCdg.code in CodeConcept.L01FY01
                        or SameCdg.code in CodeConcept.L01FD01
                        or SameCdg.code in CodeConcept.L01FD01andL01FD02exceptKC011362B5)
                )
                and MRSameCourse.dosageInstruction[0].timing.repeat.period = 3
                and MRSameCourse.dosageInstruction[0].timing.repeat.periodUnit.value = 'wk'
                and Reusable."醫令類別為1"
                and Reusable."HasValidTiming"(MRSameCourse)
                and FHIRHelpers.ToDateTime(
                  (MRSameCourse.dosageInstruction[0].timing.repeat.bounds as Period).start
                ) = FHIRHelpers.ToDateTime(
                  (MR.dosageInstruction[0].timing.repeat.bounds as Period).start
                )
              return FHIRHelpers.ToDateTime(
                (MRSameCourse.dosageInstruction[0].timing.repeat.bounds as Period).end
              )
          )
  ) <= 18
  // 僅累加代表療程的天數，避免同一療程重複加總
  and Sum(
    [MedicationRequest] MR
      where MR.intent = 'plan'
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and (Cdg.code in CodeConcept.L01FY01
                or Cdg.code in CodeConcept.L01FD01
                or Cdg.code in CodeConcept.L01FD01andL01FD02exceptKC011362B5)
        )
        and MR.dosageInstruction[0].timing.repeat.period = 3
        and MR.dosageInstruction[0].timing.repeat.periodUnit.value = 'wk'
        and MR.dosageInstruction[0].timing.repeat.bounds is Period
        and (start of (MR.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
        and (end of (MR.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
        // 若同一起始日有多筆藥物，只保留結束日最晚者作為該療程代表
        and FHIRHelpers.ToDateTime(
          (MR.dosageInstruction[0].timing.repeat.bounds as Period).end
        ) =
          Max(
            [MedicationRequest] MRSameCourse
              where MRSameCourse.intent = 'plan'
                and exists (
                  MRSameCourse.medication.coding SameCdg
                    where SameCdg in CodeConcept.NHIMedication
                      and (SameCdg.code in CodeConcept.L01FY01
                        or SameCdg.code in CodeConcept.L01FD01
                        or SameCdg.code in CodeConcept.L01FD01andL01FD02exceptKC011362B5)
                )
                and MRSameCourse.dosageInstruction[0].timing.repeat.period = 3
                and MRSameCourse.dosageInstruction[0].timing.repeat.periodUnit.value = 'wk'
                and Reusable."醫令類別為1"
                and Reusable."HasValidTiming"(MRSameCourse)
                and FHIRHelpers.ToDateTime(
                  (MRSameCourse.dosageInstruction[0].timing.repeat.bounds as Period).start
                ) = FHIRHelpers.ToDateTime(
                  (MR.dosageInstruction[0].timing.repeat.bounds as Period).start
                )
              return FHIRHelpers.ToDateTime(
                (MRSameCourse.dosageInstruction[0].timing.repeat.bounds as Period).end
              )
          )
      return all
        difference in days between
          FHIRHelpers.ToDateTime(
            (MR.dosageInstruction[0].timing.repeat.bounds as Period).start
          )
          and FHIRHelpers.ToDateTime(
            (MR.dosageInstruction[0].timing.repeat.bounds as Period).end
          )
  ) <= 378

define "1條件2=使用於外科手術前後之總療程合併計算，依藥品仿單記載以18個療程為上限":
  "1條件2-1=三種用藥合併每周療程上限18個療程"
  or "1條件2-2=三種用藥合併每三周療程上限18個療程"


define "3規則1":
"條件2-5-1=經外科手術後達病理上完全緩解者(pCR)" and "1條件2=使用於外科手術前後之總療程合併計算，依藥品仿單記載以18個療程為上限"

/*規則2*/

//本藥品與trastuzumab emtansine使用於外科手術前後的總療程合併計算，依藥品仿單記載以全部18個療程為上限，其中trastuzumab emtansine以14個療程為上限
// 每周療程: count(MR where count=1) ≤ 18 且 sum(useEdate-useSdate) ≤ 126天
define "2條件2-1=兩種用藥合併每周療程上限18個療程":
  Count(
    [MedicationRequest] MR
      where MR.intent = 'plan'
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and (Cdg.code in CodeConcept.L01FD01
                or Cdg.code in CodeConcept.L01FD03)
        )
        and MR.dosageInstruction[0].timing.repeat.count = 1
        and Reusable."醫令類別為1"
  ) <= 18
  and Sum(
    [MedicationRequest] MR
      where MR.intent = 'plan'
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and (Cdg.code in CodeConcept.L01FD01
                or Cdg.code in CodeConcept.L01FD03)
        )
        and MR.dosageInstruction[0].timing.repeat.count = 1
        and MR.dosageInstruction[0].timing.repeat.bounds is Period
        and (start of (MR.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
        and (end of (MR.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
      return all
        difference in days between
          FHIRHelpers.ToDateTime(
            (MR.dosageInstruction[0].timing.repeat.bounds as Period).start
          )
          and FHIRHelpers.ToDateTime(
            (MR.dosageInstruction[0].timing.repeat.bounds as Period).end
          )
  ) <= 126

// 每三周療程: 同一起始日視為同一療程，僅保留結束日最晚的代表醫令後，count ≤ 18 且 sum(useEdate-useSdate) ≤ 378天
define "2條件2-2=兩種用藥合併每三周療程上限18個療程":
  // 計算兩種用藥合併後的代表療程數
  Count(
    [MedicationRequest] MR
      where MR.intent = 'plan'
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and (Cdg.code in CodeConcept.L01FD01
                or Cdg.code in CodeConcept.L01FD03)
        )
        and MR.dosageInstruction[0].timing.repeat.period = 3
        and MR.dosageInstruction[0].timing.repeat.periodUnit.value = 'wk'
        and Reusable."醫令類別為1"
        and Reusable."HasValidTiming"(MR)
        // 若同一起始日有多筆藥物，只保留結束日最晚者作為該療程代表
        and FHIRHelpers.ToDateTime(
          (MR.dosageInstruction[0].timing.repeat.bounds as Period).end
        ) =
          Max(
            [MedicationRequest] MRSameCourse
              where MRSameCourse.intent = 'plan'
                and exists (
                  MRSameCourse.medication.coding SameCdg
                    where SameCdg in CodeConcept.NHIMedication
                      and (SameCdg.code in CodeConcept.L01FD01
                        or SameCdg.code in CodeConcept.L01FD03)
                )
                and MRSameCourse.dosageInstruction[0].timing.repeat.period = 3
                and MRSameCourse.dosageInstruction[0].timing.repeat.periodUnit.value = 'wk'
                and Reusable."醫令類別為1"
                and Reusable."HasValidTiming"(MRSameCourse)
                and FHIRHelpers.ToDateTime(
                  (MRSameCourse.dosageInstruction[0].timing.repeat.bounds as Period).start
                ) = FHIRHelpers.ToDateTime(
                  (MR.dosageInstruction[0].timing.repeat.bounds as Period).start
                )
              return FHIRHelpers.ToDateTime(
                (MRSameCourse.dosageInstruction[0].timing.repeat.bounds as Period).end
              )
          )
  ) <= 18
  // 僅累加代表療程的天數，避免同一療程重複加總
  and Sum(
    [MedicationRequest] MR
      where MR.intent = 'plan'
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and (Cdg.code in CodeConcept.L01FD01
                or Cdg.code in CodeConcept.L01FD03)
        )
        and MR.dosageInstruction[0].timing.repeat.period = 3
        and MR.dosageInstruction[0].timing.repeat.periodUnit.value = 'wk'
        and MR.dosageInstruction[0].timing.repeat.bounds is Period
        and (start of (MR.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
        and (end of (MR.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
        // 若同一起始日有多筆藥物，只保留結束日最晚者作為該療程代表
        and FHIRHelpers.ToDateTime(
          (MR.dosageInstruction[0].timing.repeat.bounds as Period).end
        ) =
          Max(
            [MedicationRequest] MRSameCourse
              where MRSameCourse.intent = 'plan'
                and exists (
                  MRSameCourse.medication.coding SameCdg
                    where SameCdg in CodeConcept.NHIMedication
                      and (SameCdg.code in CodeConcept.L01FD01
                        or SameCdg.code in CodeConcept.L01FD03)
                )
                and MRSameCourse.dosageInstruction[0].timing.repeat.period = 3
                and MRSameCourse.dosageInstruction[0].timing.repeat.periodUnit.value = 'wk'
                and Reusable."醫令類別為1"
                and Reusable."HasValidTiming"(MRSameCourse)
                and FHIRHelpers.ToDateTime(
                  (MRSameCourse.dosageInstruction[0].timing.repeat.bounds as Period).start
                ) = FHIRHelpers.ToDateTime(
                  (MR.dosageInstruction[0].timing.repeat.bounds as Period).start
                )
              return FHIRHelpers.ToDateTime(
                (MRSameCourse.dosageInstruction[0].timing.repeat.bounds as Period).end
              )
          )
      return all
        difference in days between
          FHIRHelpers.ToDateTime(
            (MR.dosageInstruction[0].timing.repeat.bounds as Period).start
          )
          and FHIRHelpers.ToDateTime(
            (MR.dosageInstruction[0].timing.repeat.bounds as Period).end
          )
  ) <= 378

// trastuzumab emtansine (L01FD03) 每周療程上限14個療程
define "2條件2-3=trastuzumab emtansine每周療程上限14個療程":
  Count(
    [MedicationRequest] MR
      where MR.intent = 'plan'
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and Cdg.code in CodeConcept.L01FD03
        )
        and MR.dosageInstruction[0].timing.repeat.count = 1
        and Reusable."醫令類別為1"
  ) <= 14

// trastuzumab emtansine (L01FD03) 每三周療程上限14個療程
// 同一起始日視為同一療程，僅保留結束日最晚的代表醫令
define "2條件2-4=trastuzumab emtansine每三周療程上限14個療程":
  // 計算 trastuzumab emtansine 的代表療程數
  Count(
    [MedicationRequest] MR
      where MR.intent = 'plan'
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and Cdg.code in CodeConcept.L01FD03
        )
        and MR.dosageInstruction[0].timing.repeat.period = 3
        and MR.dosageInstruction[0].timing.repeat.periodUnit.value = 'wk'
        and Reusable."醫令類別為1"
        and Reusable."HasValidTiming"(MR)
        // 若同一起始日有多筆醫令，只保留結束日最晚者作為該療程代表
        and FHIRHelpers.ToDateTime(
          (MR.dosageInstruction[0].timing.repeat.bounds as Period).end
        ) =
          Max(
            [MedicationRequest] MRSameCourse
              where MRSameCourse.intent = 'plan'
                and exists (
                  MRSameCourse.medication.coding SameCdg
                    where SameCdg in CodeConcept.NHIMedication
                      and SameCdg.code in CodeConcept.L01FD03
                )
                and MRSameCourse.dosageInstruction[0].timing.repeat.period = 3
                and MRSameCourse.dosageInstruction[0].timing.repeat.periodUnit.value = 'wk'
                and Reusable."醫令類別為1"
                and Reusable."HasValidTiming"(MRSameCourse)
                and FHIRHelpers.ToDateTime(
                  (MRSameCourse.dosageInstruction[0].timing.repeat.bounds as Period).start
                ) = FHIRHelpers.ToDateTime(
                  (MR.dosageInstruction[0].timing.repeat.bounds as Period).start
                )
              return FHIRHelpers.ToDateTime(
                (MRSameCourse.dosageInstruction[0].timing.repeat.bounds as Period).end
              )
          )
  ) <= 14

define "2條件2=兩種用藥合併療程計算上限18個療程且trastuzumab emtansine上限14個療程":
  ("2條件2-1=兩種用藥合併每周療程上限18個療程"
    and "2條件2-3=trastuzumab emtansine每周療程上限14個療程")
  or ("2條件2-2=兩種用藥合併每三周療程上限18個療程"
    and "2條件2-4=trastuzumab emtansine每三周療程上限14個療程")


define "3規則2":
  "條件2-5-2=若外科手術後無法達病理上緩解(non-pCR)"
  and "2條件2=兩種用藥合併療程計算上限18個療程且trastuzumab emtansine上限14個療程"



// 主要規定三
define "主要規定三":
  "3規則1" or "3規則2"


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and (
    "條件1-1=外科手術前後" or
    "條件2-1=HER2過度表現(IHC3+或FISH+)" or
    "條件2-2=ER陰性" or
    "條件2-3=腫瘤大於2公分。須經乳房超音波或乳房X光攝影或核磁共振診斷" or
    "條件2-4=且未發生腋下淋巴結轉移之早期乳癌患者，作為輔助性治療用藥" or
    "條件2-5-1=經外科手術後達病理上完全緩解者(pCR)" or
    "條件2-5-2=若外科手術後無法達病理上緩解(non-pCR)"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "條件1-1-1=病摘描述本藥品使用在外科手術前"
           then '● 條件1-1-1：病摘描述本藥品使用在外科手術前\n' else '') +
         (if "條件1-1-2=外科手術後"
           then '● 條件1-1-2：外科手術後使用(用藥起始日晚於手術日)\n' else '') +
         (if "條件1-2=化學療法(術前輔助治療或輔助治療)治療後"
           then '● 條件1-2：化學療法(術前輔助治療或輔助治療)治療後\n' else '') +
         (if "條件2-1=HER2過度表現(IHC3+或FISH+)"
           then '● 條件2-1：HER2過度表現(IHC3+或FISH+)\n' else '') +
         (if "條件2-2=ER陰性"
           then '● 條件2-2：ER陰性\n' else '') +
         (if "條件2-3=腫瘤大於2公分。須經乳房超音波或乳房X光攝影或核磁共振診斷"
           then '● 條件2-3：腫瘤大於2公分(已檢附3個月內影像報告)\n' else '') +
         (if "條件2-4=且未發生腋下淋巴結轉移之早期乳癌患者，作為輔助性治療用藥"
           then '● 條件2-4：未發生腋下淋巴結轉移(N=0)，作為輔助性治療用藥\n' else '') +
         (if "條件2-5-1=經外科手術後達病理上完全緩解者(pCR)"
           then '● 條件2-5-1：經外科手術後達病理上完全緩解(pCR)\n' else '') +
         (if "條件2-5-2=若外科手術後無法達病理上緩解(non-pCR)"
           then '● 條件2-5-2：外科手術後無法達病理上緩解(non-pCR)\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件
  (if Reusable."續用申請" and (
    "規則1-1=每24週須再次申請並檢附療效評估資料" or
    "規則1-2=疾病有惡化情形須停止使用"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if "規則1-1=每24週須再次申請並檢附療效評估資料"
           then '● 續用條件1：於24週內再次申請並檢附療效評估資料\n' else '') +
         (if "規則1-2=疾病有惡化情形須停止使用"
           then '● 續用條件2：已檢附前次治療後影像學報告，確認無惡化\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則
  (if "3規則1" or "3規則2"
    then '<主要規定三：藥品使用規則>\n' +
         (if "3規則1"
           then '● 規則1：達病理上完全緩解(pCR)，三種用藥合併療程符合上限(≤18個療程)\n' else '') +
         (if "3規則2"
           then '● 規則2：無法達病理上緩解(non-pCR)，兩種用藥合併療程符合上限(≤18個療程，T-DM1≤14個療程)\n' else '')
    else '')


//============================================
// 列出「不符合」項目判斷式 - 代碼或條件不符
//============================================

define function "不符合項目_代碼或條件不符"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if Reusable."初次申請" and (
    not Reusable."ICD-10使用C50" or
    not "條件2-1=HER2過度表現(IHC3+或FISH+)" or
    not "條件2-2=ER陰性"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not Reusable."ICD-10使用C50"
           then '▲ ICD代碼檢核：主要疾病之ICD代碼未使用C50\n' else '') +
         (if not "條件2-1=HER2過度表現(IHC3+或FISH+)"
           then '▲ 條件2-1：HER2非過度表現(非IHC3+或FISH+)\n' else '') +
         (if not "條件2-2=ER陰性"
           then '▲ 條件2-2：ER非陰性\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 療程超標
  (if Reusable."初次申請" and (not "3規則1" and not "3規則2")
    then '<主要規定三：藥品使用規則>\n' +
         (if not "1條件2=使用於外科手術前後之總療程合併計算，依藥品仿單記載以18個療程為上限"
           then '▲ 規則1：三種用藥(trastuzumab/pertuzumab+trastuzumab/Phesgo)合併療程超過18個療程上限\n' else '') +
         (if not "2條件2=兩種用藥合併療程計算上限18個療程且trastuzumab emtansine上限14個療程"
           then '▲ 規則2：兩種用藥合併療程超過18個療程上限，或trastuzumab emtansine超過14個療程上限\n' else '')
    else '')


//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
    not "條件1-1=外科手術前後" or
    not "條件2-3=腫瘤大於2公分。須經乳房超音波或乳房X光攝影或核磁共振診斷" or
    not "條件2-4=且未發生腋下淋巴結轉移之早期乳癌患者，作為輔助性治療用藥" or
    not "條件2-5=依下列條件之一使用"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "條件1-1=外科手術前後"
           then '▲ 條件1-1：未提供外科手術前後使用證明或化學療法治療紀錄\n' else '') +
         (if not "條件2-3=腫瘤大於2公分。須經乳房超音波或乳房X光攝影或核磁共振診斷"
           then '▲ 條件2-3：未提供3個月內之乳房超音波/X光攝影/核磁共振影像報告\n' else '') +
         (if not "條件2-4=且未發生腋下淋巴結轉移之早期乳癌患者，作為輔助性治療用藥"
           then '▲ 條件2-4：未提供癌症分期(N=0)或3個月內影像/檢查報告\n' else '') +
         (if not "條件2-5=依下列條件之一使用"
           then '▲ 條件2-5：未提供術後病理報告(pCR或non-pCR結果)\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (
    not "規則1-1=每24週須再次申請並檢附療效評估資料" or
    not "規則1-2=疾病有惡化情形須停止使用"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if not "規則1-1=每24週須再次申請並檢附療效評估資料"
           then '▲ 續用條件1：未於24週內再次申請或未檢附療效評估資料\n' else '') +
         (if not "規則1-2=疾病有惡化情形須停止使用"
           then '▲ 續用條件2：未提供前次治療後影像學報告\n' else '') +
         '\n'
    else '')


//============================================
// 審核結果
//============================================

define "乳癌Trastuzumab申請結果_布林":
  case
    when Reusable."初次申請" then (
      "主要規定一" and
      "主要規定三"
    )
    when Reusable."續用申請" then
      "主要規定二"
    else false
  end

define "乳癌Trastuzumab申請之CQL檢核結果":
  if (
    Reusable."初次申請" and
    "主要規定一" and
    "主要規定三"
  )
  then '✓通過：初次使用－乳癌Trastuzumab用藥申請'

  else if (
    Reusable."續用申請" and
    "主要規定二"
  )
  then '✓通過：續用－乳癌Trastuzumab用藥申請'

  else if Reusable."初次申請"
  then '✖不通過：初次使用－乳癌Trastuzumab用藥申請'

  else if Reusable."續用申請"
  then '✖不通過：續用－乳癌Trastuzumab用藥申請'

  else '✖不通過：無法判定申請類型－乳癌Trastuzumab用藥申請'


//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 乳癌之Trastuzumab申請審核報告 ===\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 代碼或條件不符】\n' +
  (if "不符合項目_代碼或條件不符"() = '' then '無\n' else "不符合項目_代碼或條件不符"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【申請結果】\n' +
  "乳癌Trastuzumab申請之CQL檢核結果" +
  '\n===============================================\n'
