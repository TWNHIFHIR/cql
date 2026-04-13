//早期乳癌_Trastuzumab Emtansine給付規定
library BCTrastuzumabEmtansineRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include BCCodeConcept version '1.0.0' called CodeConcept

include BCReusable version '1.0.0' called Reusable

context Patient


//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/

//1條件1:使用於具HER2過度表現(IHC 3+或FISH+)之早期乳癌病人
define "1條件1=檢驗檢查-HER2過度表現(IHC3+或FISH+)":
  Reusable."HasHER2OverexpressionTest"

define "1條件1=基因檢測-HER2過度表現(IHC3+或FISH+)":
  Reusable."HasHER2OverexpressionGene"

define "1條件1=使用於具HER2過度表現(IHC 3+或FISH+)之早期乳癌病人":
  "1條件1=檢驗檢查-HER2過度表現(IHC3+或FISH+)"
  or "1條件1=基因檢測-HER2過度表現(IHC3+或FISH+)"


//1條件2:曾接受過至少6個療程（每3週一療程，至少16週）的化學治療（其中至少3個療程(9週)的taxane藥物）
//1條件2-1:每三周療程之非taxane化學治療，合併計算各種化療藥物之療程，至少3個療程且總療程天數至少49天
// 同一起始日視為同一療程；若同一療程內有多筆非taxane藥物，只保留結束日最晚的那筆代表該療程
define "1條件2-1=曾接受過至少3個療程（每3週一療程，至少7週）的非taxane化學治療":
  // 計算符合條件的代表療程數；每個起始日只保留結束日最晚的一筆
  Count(
    [MedicationRequest] MROrder1
      where MROrder1.intent = 'order'
        and exists (
          MROrder1.medication.coding Cdg1
            where Cdg1 in CodeConcept.NHIMedication
              and Cdg1.code in CodeConcept."非taxane化學治療"
        )
        and MROrder1.dosageInstruction[0].timing.repeat.period = 3
        and MROrder1.dosageInstruction[0].timing.repeat.periodUnit.value = 'wk'
        and Reusable."HasValidTiming"(MROrder1)
        // 若同一起始日有多筆藥物，只保留結束日最晚者作為該療程代表
        and FHIRHelpers.ToDateTime(
          (MROrder1.dosageInstruction[0].timing.repeat.bounds as Period).end
        ) =
          Max(
            [MedicationRequest] MRSameCourse1
              where MRSameCourse1.intent = 'order'
                and exists (
                  MRSameCourse1.medication.coding SameCdg1
                    where SameCdg1 in CodeConcept.NHIMedication
                      and SameCdg1.code in CodeConcept."非taxane化學治療"
                )
                and MRSameCourse1.dosageInstruction[0].timing.repeat.period = 3
                and MRSameCourse1.dosageInstruction[0].timing.repeat.periodUnit.value = 'wk'
                and Reusable."HasValidTiming"(MRSameCourse1)
                and FHIRHelpers.ToDateTime(
                  (MRSameCourse1.dosageInstruction[0].timing.repeat.bounds as Period).start
                ) = FHIRHelpers.ToDateTime(
                  (MROrder1.dosageInstruction[0].timing.repeat.bounds as Period).start
                )
              return FHIRHelpers.ToDateTime(
                (MRSameCourse1.dosageInstruction[0].timing.repeat.bounds as Period).end
              )
          )
  ) >= 3
  // 只累加代表療程的天數，避免同一療程內多筆藥物重複計算
  and Sum(
    [MedicationRequest] MROrder2
      where MROrder2.intent = 'order'
        and exists (
          MROrder2.medication.coding Cdg2
            where Cdg2 in CodeConcept.NHIMedication
              and Cdg2.code in CodeConcept."非taxane化學治療"
        )
        and MROrder2.dosageInstruction[0].timing.repeat.period = 3
        and MROrder2.dosageInstruction[0].timing.repeat.periodUnit.value = 'wk'
        and Reusable."HasValidTiming"(MROrder2)
        // 若同一起始日有多筆藥物，只保留結束日最晚者作為該療程代表
        and FHIRHelpers.ToDateTime(
          (MROrder2.dosageInstruction[0].timing.repeat.bounds as Period).end
        ) =
          Max(
            [MedicationRequest] MRSameCourse2
              where MRSameCourse2.intent = 'order'
                and exists (
                  MRSameCourse2.medication.coding SameCdg2
                    where SameCdg2 in CodeConcept.NHIMedication
                      and SameCdg2.code in CodeConcept."非taxane化學治療"
                )
                and MRSameCourse2.dosageInstruction[0].timing.repeat.period = 3
                and MRSameCourse2.dosageInstruction[0].timing.repeat.periodUnit.value = 'wk'
                and Reusable."HasValidTiming"(MRSameCourse2)
                and FHIRHelpers.ToDateTime(
                  (MRSameCourse2.dosageInstruction[0].timing.repeat.bounds as Period).start
                ) = FHIRHelpers.ToDateTime(
                  (MROrder2.dosageInstruction[0].timing.repeat.bounds as Period).start
                )
              return FHIRHelpers.ToDateTime(
                (MRSameCourse2.dosageInstruction[0].timing.repeat.bounds as Period).end
              )
          )
      return all
        difference in days between
          FHIRHelpers.ToDateTime(
            (MROrder2.dosageInstruction[0].timing.repeat.bounds as Period).start
          )
          and FHIRHelpers.ToDateTime(
            (MROrder2.dosageInstruction[0].timing.repeat.bounds as Period).end
          )
  ) >= 49


//1條件2-2:3個療程(9週)的taxane藥物
define "1條件2-2=3個療程(9週)的taxane藥物":
  // 計算符合條件的代表療程數；每個起始日只保留結束日最晚的一筆
  Count(
    [MedicationRequest] MROrder1
      where MROrder1.intent = 'order'
        and exists (
          MROrder1.medication.coding Cdg1
            where Cdg1 in CodeConcept.NHIMedication
              and (Cdg1.code in CodeConcept.L01CD01
                or Cdg1.code in CodeConcept.L01CD02)
        )
        and MROrder1.dosageInstruction[0].timing.repeat.period = 3
        and MROrder1.dosageInstruction[0].timing.repeat.periodUnit.value = 'wk'
        and Reusable."HasValidTiming"(MROrder1)
        // 若同一起始日有多筆藥物，只保留結束日最晚者作為該療程代表
        and FHIRHelpers.ToDateTime(
          (MROrder1.dosageInstruction[0].timing.repeat.bounds as Period).end
        ) =
          Max(
            [MedicationRequest] MRSameCourse1
              where MRSameCourse1.intent = 'order'
                and exists (
                  MRSameCourse1.medication.coding SameCdg1
                    where SameCdg1 in CodeConcept.NHIMedication
                      and (SameCdg1.code in CodeConcept.L01CD01
                        or SameCdg1.code in CodeConcept.L01CD02)
                )
                and MRSameCourse1.dosageInstruction[0].timing.repeat.period = 3
                and MRSameCourse1.dosageInstruction[0].timing.repeat.periodUnit.value = 'wk'
                and Reusable."HasValidTiming"(MRSameCourse1)
                and FHIRHelpers.ToDateTime(
                  (MRSameCourse1.dosageInstruction[0].timing.repeat.bounds as Period).start
                ) = FHIRHelpers.ToDateTime(
                  (MROrder1.dosageInstruction[0].timing.repeat.bounds as Period).start
                )
              return FHIRHelpers.ToDateTime(
                (MRSameCourse1.dosageInstruction[0].timing.repeat.bounds as Period).end
              )
          )
  ) >= 3
  // 只累加代表療程的天數，避免同一療程內多筆藥物重複計算
  and Sum(
    [MedicationRequest] MROrder2
      where MROrder2.intent = 'order'
        and exists (
          MROrder2.medication.coding Cdg2
            where Cdg2 in CodeConcept.NHIMedication
              and (Cdg2.code in CodeConcept.L01CD01
                or Cdg2.code in CodeConcept.L01CD02)
        )
        and MROrder2.dosageInstruction[0].timing.repeat.period = 3
        and MROrder2.dosageInstruction[0].timing.repeat.periodUnit.value = 'wk'
        and Reusable."HasValidTiming"(MROrder2)
        // 若同一起始日有多筆藥物，只保留結束日最晚者作為該療程代表
        and FHIRHelpers.ToDateTime(
          (MROrder2.dosageInstruction[0].timing.repeat.bounds as Period).end
        ) =
          Max(
            [MedicationRequest] MRSameCourse2
              where MRSameCourse2.intent = 'order'
                and exists (
                  MRSameCourse2.medication.coding SameCdg2
                    where SameCdg2 in CodeConcept.NHIMedication
                      and (SameCdg2.code in CodeConcept.L01CD01
                        or SameCdg2.code in CodeConcept.L01CD02)
                )
                and MRSameCourse2.dosageInstruction[0].timing.repeat.period = 3
                and MRSameCourse2.dosageInstruction[0].timing.repeat.periodUnit.value = 'wk'
                and Reusable."HasValidTiming"(MRSameCourse2)
                and FHIRHelpers.ToDateTime(
                  (MRSameCourse2.dosageInstruction[0].timing.repeat.bounds as Period).start
                ) = FHIRHelpers.ToDateTime(
                  (MROrder2.dosageInstruction[0].timing.repeat.bounds as Period).start
                )
              return FHIRHelpers.ToDateTime(
                (MRSameCourse2.dosageInstruction[0].timing.repeat.bounds as Period).end
              )
          )
      return all
        difference in days between
          FHIRHelpers.ToDateTime(
            (MROrder2.dosageInstruction[0].timing.repeat.bounds as Period).start
          )
          and FHIRHelpers.ToDateTime(
            (MROrder2.dosageInstruction[0].timing.repeat.bounds as Period).end
          )
  ) >= 63


define "1條件2=曾接受過至少6個療程的化學治療":
"1條件2-1=曾接受過至少3個療程（每3週一療程，至少7週）的非taxane化學治療"
and "1條件2-2=3個療程(9週)的taxane藥物"


//1條件3:至少3個療程(9週)的trastuzumab術前輔助治療，仍有殘留病灶的術後輔助治療
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

define "病摘敘明trastuzumab術前輔助治療後仍有殘留病灶":
    exists (
        [Claim] C
        where exists (
            C.diagnosis D
            where exists (
                D.type.text T
                where Matches(T.value, '(?i).*(trastuzumab術前輔助治療後仍有殘留病灶).*')
            )
        )
    )

define "至少3個療程(9週)的trastuzumab術前輔助治療，仍有殘留病灶的術後輔助治療":
  Count(
    [MedicationRequest] MROrder1
    where MROrder1.intent = 'order'
      and exists (
        MROrder1.medication.coding Cdg1
        where Cdg1 in CodeConcept.NHIMedication
          and Cdg1.code in CodeConcept.L01FD01
      )
      and MROrder1.dosageInstruction[0].timing.repeat.period = 3
      and MROrder1.dosageInstruction[0].timing.repeat.periodUnit.value = 'wk'
      and Reusable."HasValidTiming"(MROrder1)
      and "手術日期(opdate)" > FHIRHelpers.ToDateTime(
        (MROrder1.dosageInstruction[0].timing.repeat.bounds as Period).start
      )
      and FHIRHelpers.ToDateTime(
        (MROrder1.dosageInstruction[0].timing.repeat.bounds as Period).end
      ) =
        Max(
          [MedicationRequest] MRSameCourse1
          where MRSameCourse1.intent = 'order'
            and exists (
              MRSameCourse1.medication.coding SameCdg1
              where SameCdg1 in CodeConcept.NHIMedication
                and SameCdg1.code in CodeConcept.L01FD01
            )
            and MRSameCourse1.dosageInstruction[0].timing.repeat.period = 3
            and MRSameCourse1.dosageInstruction[0].timing.repeat.periodUnit.value = 'wk'
            and Reusable."HasValidTiming"(MRSameCourse1)
            and FHIRHelpers.ToDateTime(
              (MRSameCourse1.dosageInstruction[0].timing.repeat.bounds as Period).start
            ) = FHIRHelpers.ToDateTime(
              (MROrder1.dosageInstruction[0].timing.repeat.bounds as Period).start
            )
          return FHIRHelpers.ToDateTime(
            (MRSameCourse1.dosageInstruction[0].timing.repeat.bounds as Period).end
          )
        )
  ) >= 3
  and Sum(
    [MedicationRequest] MROrder2
    where MROrder2.intent = 'order'
      and exists (
        MROrder2.medication.coding Cdg2
        where Cdg2 in CodeConcept.NHIMedication
          and Cdg2.code in CodeConcept.L01FD01
      )
      and MROrder2.dosageInstruction[0].timing.repeat.period = 3
      and MROrder2.dosageInstruction[0].timing.repeat.periodUnit.value = 'wk'
      and Reusable."HasValidTiming"(MROrder2)
      and "手術日期(opdate)" > FHIRHelpers.ToDateTime(
        (MROrder2.dosageInstruction[0].timing.repeat.bounds as Period).start
      )
      and FHIRHelpers.ToDateTime(
        (MROrder2.dosageInstruction[0].timing.repeat.bounds as Period).end
      ) =
        Max(
          [MedicationRequest] MRSameCourse2
          where MRSameCourse2.intent = 'order'
            and exists (
              MRSameCourse2.medication.coding SameCdg2
              where SameCdg2 in CodeConcept.NHIMedication
                and SameCdg2.code in CodeConcept.L01FD01
            )
            and MRSameCourse2.dosageInstruction[0].timing.repeat.period = 3
            and MRSameCourse2.dosageInstruction[0].timing.repeat.periodUnit.value = 'wk'
            and Reusable."HasValidTiming"(MRSameCourse2)
            and FHIRHelpers.ToDateTime(
              (MRSameCourse2.dosageInstruction[0].timing.repeat.bounds as Period).start
            ) = FHIRHelpers.ToDateTime(
              (MROrder2.dosageInstruction[0].timing.repeat.bounds as Period).start
            )
          return FHIRHelpers.ToDateTime(
            (MRSameCourse2.dosageInstruction[0].timing.repeat.bounds as Period).end
          )
        )
    return all
      difference in days between
        FHIRHelpers.ToDateTime(
          (MROrder2.dosageInstruction[0].timing.repeat.bounds as Period).start
        )
        and FHIRHelpers.ToDateTime(
          (MROrder2.dosageInstruction[0].timing.repeat.bounds as Period).end
        )
  ) >= 63

define "1條件3=至少3個療程(9週)的trastuzumab術前輔助治療，仍有殘留病灶的術後輔助治療":
"病摘敘明trastuzumab術前輔助治療後仍有殘留病灶"
and "至少3個療程(9週)的trastuzumab術前輔助治療，仍有殘留病灶的術後輔助治療"
and "本次申請紀錄" is not null
and Reusable."醫令類別為1"


//條件4:需符合下列任一條件
//I.具腋下淋巴結轉移但無遠處臟器轉移之早期乳癌病人。
//Ⅱ.未發生腋下淋巴結轉移，但雌激素受體(ER)為陰性且腫瘤大於2公分之早期乳癌病人。

//1條件4-1:具腋下淋巴結轉移但無遠處臟器轉移之早期乳癌病人
define "ICD代碼檢核_布林值": Reusable."ICD-10使用C50"

define "醫令類別為1_布林值":Reusable."醫令類別為1"

//1條件4-1-1:具腋下淋巴結轉移
define "1條件4-1-1=具腋下淋巴結轉移":
  exists (
    [Observation] O
      where exists (
        O.code.coding Cdg
          where Cdg.code = '399390009'
            and Cdg in CodeConcept.SNOMED
      )
        and O.value is not null
        and O.value is FHIR.string
        and Matches((O.value as FHIR.string).value, '.*N[1-9].*')
  )

//1條件4-1-2:但無遠處臟器轉移之早期乳癌病人
define "1條件4-1-2=癌症分期分數或結果為M=0":
  Reusable."癌症分期分數或結果為M=0"

define "1條件4-1-2=3個月內影像報告":
Reusable."HasRecentImageReport"("本次申請起始日期", 90)


define "1條件4-1-2=3個月內有檢查報告":
Reusable."HasRecentMolecularReport"("本次申請起始日期", 90)

define "1條件4-1-2=但無遠處臟器轉移之早期乳癌病人":
  Reusable."ICD-10使用C50"
  and "1條件4-1-2=癌症分期分數或結果為M=0"
  and "1條件4-1-2=3個月內影像報告"
  or "1條件4-1-2=3個月內有檢查報告"
  


define "1條件4-1=具腋下淋巴結轉移但無遠處臟器轉移之早期乳癌病人":
  "1條件4-1-1=具腋下淋巴結轉移"
    and not "1條件4-1-2=但無遠處臟器轉移之早期乳癌病人"


//1條件4-2:未發生腋下淋巴結轉移，但雌激素受體(ER)為陰性且腫瘤大於2公分之早期乳癌病人
//1條件4-2-1:未發生腋下淋巴結轉移
define "1條件4-2-1=未發生腋下淋巴結轉移":
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

////1條件4-2-2:雌激素受體(ER)為陰性
define "1條件4-2-2=檢驗檢查-ER陰性":
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
            and INT.code in {'NEG'}
      )
      and OBs.value is string
      and Matches(OBs.value as string, '(?i).*([-−]|0|陰性|negative).*')
  )

define "1條件4-2-2=基因檢測-ER陰性":
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
        and exists (
          Comp.interpretation.coding INT
            where INT in CodeConcept.InterpretationCodes
              and INT.code in {'NEG'}
        )
        and exists (
          Comp.interpretation I
            where Matches(I.text, '(?i).*([-−]|0|陰性|negative).*')
        )
    )
  )

define "1條件4-2-2=E雌激素受體(ER)為陰性":
  "1條件4-2-2=檢驗檢查-ER陰性" or "1條件4-2-2=基因檢測-ER陰性"


////1條件4-2-3:病摘敘明腫瘤大於2公分
define "1條件4-2-3=病摘敘明腫瘤大於2公分":
    exists (
        [Claim] C
        where exists (
            C.diagnosis D
            where exists (
                D.type.text T
                where Matches(T.value, '(?i).*(腫瘤大於2公分).*')
            )
        )
    )

define "1條件4-2-3=腫瘤大於2公分之早期乳癌病人":
  Reusable."ICD-10使用C50"
  and "1條件4-2-3=病摘敘明腫瘤大於2公分"
  and "1條件4-1-2=3個月內影像報告"

define "1條件4-2＝未發生腋下淋巴結轉移，但雌激素受體(ER)為陰性且腫瘤大於2公分之早期乳癌病人":
"1條件4-2-1=未發生腋下淋巴結轉移" 
and "1條件4-2-2=E雌激素受體(ER)為陰性"
and "1條件4-2-3=腫瘤大於2公分之早期乳癌病人"

define "1條件4=需符合下列任一條件":
  "1條件4-1=具腋下淋巴結轉移但無遠處臟器轉移之早期乳癌病人"
  or "1條件4-2＝未發生腋下淋巴結轉移，但雌激素受體(ER)為陰性且腫瘤大於2公分之早期乳癌病人"
//主要規定一
define "主要規定一":
"1條件1=使用於具HER2過度表現(IHC 3+或FISH+)之早期乳癌病人"
and "1條件2=曾接受過至少6個療程的化學治療"
//and "1條件3=至少3個療程(9週)的trastuzumab術前輔助治療，仍有殘留病灶的術後輔助治療"
and "1條件4=需符合下列任一條件"

//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

//條件1:核准後每24週須檢附療效評估資料再次申請，若疾病有惡化情形即不應再行申請

// 本次申請紀錄（以最新一筆申請作為本次申請）
define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.L01FD03)

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

// 前次申請紀錄（本次申請之前最近一次的申請）
define "前次申請紀錄":
  Reusable."LatestMedicationPlanBefore"(CodeConcept.L01FD03, "本次申請起始日期")

// 檢查本次申請療程長度是否在24週內
define "規則1-1=每24週須再次申請並檢附療效評估資料":
  Reusable."醫令類別為1" 
  and Reusable."續用註記為2"
  and "本次申請紀錄" is not null
  and Reusable."HasMedicationPlanPeriodWithinDays"(CodeConcept.L01FD03, 168)


//條件2:疾病有惡化情形須停止使用

// 取得前次治療紀錄（最近一次已完成的治療）
define "前次治療紀錄":
  Reusable."LatestCompletedMedicationOrderBefore"(CodeConcept.L01FD03, "本次申請起始日期")

// 前次用藥開始日期
define "前次用藥開始日期":
  Reusable."GetStartTime"("前次治療紀錄")

// 規則1-2: 疾病有惡化情形須停止使用(續用須檢附前次治療後影像學報告)
define "規則1-2=疾病有惡化情形須停止使用":
  Reusable."HasImageReportBetweenPreviousTreatmentAndCurrentApply"(CodeConcept.L01FD03)

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

define "符合條件之本藥品處方":
  [MedicationRequest] MRTotal
    where (MRTotal.intent = 'plan' or MRTotal.intent = 'order')
      and (MRTotal.status is null or MRTotal.status in { 'active', 'completed', 'on-hold' })
      and exists MRTotal.dosageInstruction
      and MRTotal.dosageInstruction[0].timing.repeat.bounds is Period
      and start of (MRTotal.dosageInstruction[0].timing.repeat.bounds as Period) is not null
      and end of (MRTotal.dosageInstruction[0].timing.repeat.bounds as Period) is not null
      and exists (
        MRTotal.medication.coding Cdg
          where Cdg in CodeConcept.NHIMedication
            and Cdg.code in CodeConcept.L01FD03
      )

define "規則1=每位病人使用本藥品以14個療程為上限":
  Sum(
    "符合條件之本藥品處方" MRTotal
      return
        duration in days between
          start of (MRTotal.dosageInstruction[0].timing.repeat.bounds as Period)
          and end of (MRTotal.dosageInstruction[0].timing.repeat.bounds as Period)
  ) <= 294


/*規則2*/

define "2條件1=未於術後12週內開始治療或提出治療申請":
  exists (
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
    and duration in days between "手術日期(opdate)" and "本次申請起始日期" > 84
  ) 
  and "本次申請紀錄" is not null 

/*規則3*/

define "左心室射出分率少於45%":
    exists (
        [Claim] C
        where exists (
            C.diagnosis D
            where exists (
                D.type.text T
                where Matches(T.value, '(?i).*(左心室射出分率少於45%).*')
            )
        )
    )

define "有症狀的心衰竭病人":
  exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where D.sequence >= 2
            and exists ( 
              D.diagnosis.coding Cdg
                where (
                  Cdg in CodeConcept.ICD10CM2023
                  or Cdg in CodeConcept.ICD10CM2014
                )
                and Substring(Cdg.code, 0, 3) = 'I50'
            )
      )
  )

define "2條件2":
"左心室射出分率少於45%" or "有症狀的心衰竭病人"

define "2條件3=不得與其他抗HER2藥物併用":
  exists (
    [MedicationRequest] MROrder1
    where (MROrder1.intent = 'plan' or MROrder1.intent = 'order')
      and (MROrder1.status is null or MROrder1.status in { 'active', 'completed' })
      and exists (
        MROrder1.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
          and Cdg.code in CodeConcept."抗HER2藥物併用"
      )
  )

define "規則2":
"2條件1=未於術後12週內開始治療或提出治療申請" 
or "2條件2"
or "2條件3=不得與其他抗HER2藥物併用"

/*規則3*/

//3條件1:本藥品申請通過後，如轉換成trastuzumab或其他抗HER2藥物後不得再次申請本藥品
define "3條件1=本藥品申請通過後，如轉換成trastuzumab或其他抗HER2藥物後不得再次申請本藥品":
  exists (
    from
      [MedicationRequest] CurrentDrug,
      [MedicationRequest] PrevDrug,
      [MedicationRequest] PrevHer2
    where CurrentDrug.intent = 'order'
      and (CurrentDrug.status is null or CurrentDrug.status in { 'active', 'completed', 'on-hold' })
      and exists CurrentDrug.dosageInstruction
      and CurrentDrug.dosageInstruction[0].timing.repeat.bounds is Period
      and start of (CurrentDrug.dosageInstruction[0].timing.repeat.bounds as Period) is not null
      and exists (
        CurrentDrug.medication.coding CdgCurrent
          where CdgCurrent in CodeConcept.NHIMedication
            and CdgCurrent.code in CodeConcept.L01FD03
      )

      and (PrevDrug.intent = 'plan' or PrevDrug.intent = 'order')
      and (PrevDrug.status is null or PrevDrug.status in { 'active', 'completed', 'on-hold' })
      and exists PrevDrug.dosageInstruction
      and PrevDrug.dosageInstruction[0].timing.repeat.bounds is Period
      and start of (PrevDrug.dosageInstruction[0].timing.repeat.bounds as Period) is not null
      and exists (
        PrevDrug.medication.coding CdgPrevDrug
          where CdgPrevDrug in CodeConcept.NHIMedication
            and CdgPrevDrug.code in CodeConcept.L01FD03
      )

      and (PrevHer2.intent = 'plan' or PrevHer2.intent = 'order')
      and (PrevHer2.status is null or PrevHer2.status in { 'active', 'completed', 'on-hold' })
      and exists PrevHer2.dosageInstruction
      and PrevHer2.dosageInstruction[0].timing.repeat.bounds is Period
      and start of (PrevHer2.dosageInstruction[0].timing.repeat.bounds as Period) is not null
      and exists (
        PrevHer2.medication.coding CdgHer2
          where CdgHer2 in CodeConcept.NHIMedication
            and CdgHer2.code in CodeConcept."抗HER2藥物併用"
      )

      and start of (PrevDrug.dosageInstruction[0].timing.repeat.bounds as Period)
          < start of (PrevHer2.dosageInstruction[0].timing.repeat.bounds as Period)

      and start of (PrevHer2.dosageInstruction[0].timing.repeat.bounds as Period)
          < start of (CurrentDrug.dosageInstruction[0].timing.repeat.bounds as Period)
  )

//3條件2:本藥品與trastuzumab使用於早期乳癌手術前後的總療程合併計算，每位病人以全部18個療程為上限
define "符合條件之兩種用藥處方":
  [MedicationRequest] MR
    where (
      (MR.intent = 'plan'
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and Cdg.code in CodeConcept.L01FD03
        ))
      or
      (MR.intent = 'order'
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and Cdg.code in CodeConcept.L01FD01
        ))
    )
      and (MR.status is null or MR.status in { 'active', 'completed', 'on-hold' })
      and exists MR.dosageInstruction
      and MR.dosageInstruction[0].timing.repeat.bounds is Period
      and start of (MR.dosageInstruction[0].timing.repeat.bounds as Period) is not null
      and end of (MR.dosageInstruction[0].timing.repeat.bounds as Period) is not null

define "3條件2=本藥品與trastuzumab使用於早期乳癌手術前後的總療程合併計算，每位病人以全部18個療程為上限":
  Sum(
    "符合條件之兩種用藥處方" MR
      return
        duration in days between
          start of (MR.dosageInstruction[0].timing.repeat.bounds as Period)
          and end of (MR.dosageInstruction[0].timing.repeat.bounds as Period)
  ) <= 378

define "規則3":
not "3條件1=本藥品申請通過後，如轉換成trastuzumab或其他抗HER2藥物後不得再次申請本藥品"
and "3條件2=本藥品與trastuzumab使用於早期乳癌手術前後的總療程合併計算，每位病人以全部18個療程為上限"

//主要規定三
define "主要規定三":
"規則1=每位病人使用本藥品以14個療程為上限"
and not "規則2"
and "規則3"


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and (
    "1條件1=使用於具HER2過度表現(IHC 3+或FISH+)之早期乳癌病人" or
    "1條件2=曾接受過至少6個療程的化學治療" or
    "1條件4=需符合下列任一條件"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "1條件1=使用於具HER2過度表現(IHC 3+或FISH+)之早期乳癌病人"
           then '● 條件1：HER2過度表現(IHC3+或FISH+)\n' else '') +
         (if "1條件2-1=曾接受過至少3個療程（每3週一療程，至少7週）的非taxane化學治療"
           then '● 條件2-1：曾接受過至少3個療程非taxane化學治療(≥3療程且≥49天)\n' else '') +
         (if "1條件2-2=3個療程(9週)的taxane藥物"
           then '● 條件2-2：曾接受過至少3個療程taxane化學治療(≥3療程且≥63天)\n' else '') +
         (if "1條件4-1=具腋下淋巴結轉移但無遠處臟器轉移之早期乳癌病人"
           then '● 條件4-1：具腋下淋巴結轉移(N≥1)且無遠處臟器轉移(M=0)\n' else '') +
         (if "1條件4-2＝未發生腋下淋巴結轉移，但雌激素受體(ER)為陰性且腫瘤大於2公分之早期乳癌病人"
           then '● 條件4-2：未發生腋下淋巴結轉移(N=0)，ER陰性且腫瘤大於2公分\n' else '') +
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
  (if "規則1=每位病人使用本藥品以14個療程為上限" or "規則3"
    then '<主要規定三：藥品使用規則>\n' +
         (if "規則1=每位病人使用本藥品以14個療程為上限"
           then '● 規則1：本藥品使用療程符合14個療程上限(≤294天)\n' else '') +
         (if not "2條件1=未於術後12週內開始治療或提出治療申請"
           then '● 規則2-1：於術後12週(84天)內開始治療或提出申請\n' else '') +
         (if not "2條件2"
           then '● 規則2-2：無左心室射出分率少於45%或有症狀心衰竭之禁忌症\n' else '') +
         (if not "2條件3=不得與其他抗HER2藥物併用"
           then '● 規則2-3：未與其他抗HER2藥物併用\n' else '') +
         (if not "3條件1=本藥品申請通過後，如轉換成trastuzumab或其他抗HER2藥物後不得再次申請本藥品"
           then '● 規則3-1：未曾由本藥品轉換為其他抗HER2藥物後再次申請本藥品\n' else '') +
         (if "3條件2=本藥品與trastuzumab使用於早期乳癌手術前後的總療程合併計算，每位病人以全部18個療程為上限"
           then '● 規則3-2：與trastuzumab合併計算療程符合18個療程上限(≤378天)\n' else '')
    else '')


//============================================
// 列出「不符合」項目判斷式 - 代碼或條件不符
//============================================

define function "不符合項目_代碼或條件不符"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if Reusable."初次申請" and (
    not Reusable."ICD-10使用C50" or
    not "1條件1=使用於具HER2過度表現(IHC 3+或FISH+)之早期乳癌病人"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not Reusable."ICD-10使用C50"
           then '▲ ICD代碼檢核：主要疾病之ICD代碼未使用C50\n' else '') +
         (if not "1條件1=使用於具HER2過度表現(IHC 3+或FISH+)之早期乳癌病人"
           then '▲ 條件1：HER2非過度表現(非IHC3+或FISH+)\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 療程超標或條件不符
  (if not "規則1=每位病人使用本藥品以14個療程為上限"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則1：本藥品使用療程超過14個療程上限(294天)\n' + '\n'
    else '') +

  (if "2條件2"
    then '<主要規定三：藥品使用規則>\n' +
         (if "左心室射出分率少於45%"
           then '▲ 規則2：病人左心室射出分率少於45%，不符合用藥條件\n' else '') +
         (if "有症狀的心衰竭病人"
           then '▲ 規則2：病人為有症狀的心衰竭病人，不符合用藥條件\n' else '') +
         '\n'
    else '') +

  (if "2條件3=不得與其他抗HER2藥物併用"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則2-3：病人同時使用其他抗HER2藥物，違反不得併用規定\n' + '\n'
    else '') +

  (if "3條件1=本藥品申請通過後，如轉換成trastuzumab或其他抗HER2藥物後不得再次申請本藥品"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則3-1：曾轉換為trastuzumab或其他抗HER2藥物後再次申請本藥品\n' + '\n'
    else '') +

  (if not "3條件2=本藥品與trastuzumab使用於早期乳癌手術前後的總療程合併計算，每位病人以全部18個療程為上限"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則3-2：與trastuzumab合併計算療程超過18個療程上限(378天)\n' + '\n'
    else '')


//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
    not "1條件2=曾接受過至少6個療程的化學治療" or
    not "1條件4=需符合下列任一條件"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "1條件2=曾接受過至少6個療程的化學治療"
           then '▲ 條件2：未提供至少6個療程化學治療紀錄(須含至少3療程非taxane及3療程taxane)\n' else '') +
         (if not "1條件4=需符合下列任一條件"
           then '▲ 條件4：未提供腋下淋巴結轉移與癌症分期(M=0)資料，或未提供ER陰性/腫瘤大於2公分之證明及3個月內影像報告\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (
    not "規則1-1=每24週須再次申請並檢附療效評估資料" or
    not "規則1-2=疾病有惡化情形須停止使用"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if not "規則1-1=每24週須再次申請並檢附療效評估資料"
           then '▲ 續用條件1：未於24週內再次申請，或未檢附療效評估資料，或申請療程超過24週(168天)\n' else '') +
         (if not "規則1-2=疾病有惡化情形須停止使用"
           then '▲ 續用條件2：未提供前次治療後之影像學報告\n' else '') +
         '\n'
    else '') +

  // 主要規定三：術後時程 - 必要資料未填寫
  (if Reusable."初次申請" and "2條件1=未於術後12週內開始治療或提出治療申請"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則2-1：未提供手術相關報告，或申請時距手術日期已超過12週(84天)\n' + '\n'
    else '')


//============================================
// 審核結果
//============================================

define "乳癌TrastuzumabEmtansine早期申請結果_布林":
  case
    when Reusable."初次申請" then (
      "主要規定一" and
      "主要規定三"
    )
    when Reusable."續用申請" then
      "主要規定二"
    else false
  end

define "乳癌TrastuzumabEmtansine早期申請之CQL檢核結果":
  if (
    Reusable."初次申請" and
    "主要規定一" and
    "主要規定三"
  )
  then '✓通過：初次使用－早期乳癌Trastuzumab Emtansine用藥申請'

  else if (
    Reusable."續用申請" and
    "主要規定二"
  )
  then '✓通過：續用－早期乳癌Trastuzumab Emtansine用藥申請'

  else if Reusable."初次申請"
  then '✖不通過：初次使用－早期乳癌Trastuzumab Emtansine用藥申請'

  else if Reusable."續用申請"
  then '✖不通過：續用－早期乳癌Trastuzumab Emtansine用藥申請'

  else '✖不通過：無法判定申請類型－早期乳癌Trastuzumab Emtansine用藥申請'


//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 早期乳癌之Trastuzumab Emtansine申請審核報告 ===\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 代碼或條件不符】\n' +
  (if "不符合項目_代碼或條件不符"() = '' then '無\n' else "不符合項目_代碼或條件不符"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【申請結果】\n' +
  "乳癌TrastuzumabEmtansine早期申請之CQL檢核結果" +
  '\n===============================================\n'
