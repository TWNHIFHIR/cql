//轉移性乳癌_Trastuzumab給付規定
library BCTrastuzumabRule3 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include BCCodeConcept version '1.0.0' called CodeConcept

include BCReusable version '1.0.0' called Reusable

context Patient



//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/

define "ICD代碼檢核_布林值": Reusable."ICD-10使用C50"

define "醫令類別為1_布林值":Reusable."醫令類別為1"

//條件1:單獨使用於治療腫瘤細胞上有HER2過度表現(IHC3+或FISH+)，曾接受過一次以上化學治療之轉移性乳癌病人

//條件1-1:單獨使用於治療腫瘤細胞上有HER2過度表現(IHC3+或FISH+)
define "條件1-1=檢驗檢查-HER2過度表現(IHC3+或FISH+)":
  Reusable."HasHER2OverexpressionTest"

define "條件1-1=基因檢測-HER2過度表現(IHC3+或FISH+)":
  Reusable."HasHER2OverexpressionGene"

define "條件1-1=HER2過度表現(IHC3+或FISH+)":
  "條件1-1=檢驗檢查-HER2過度表現(IHC3+或FISH+)"
  or "條件1-1=基因檢測-HER2過度表現(IHC3+或FISH+)"

define "條件1-1=單獨使用於治療腫瘤細胞上有HER2過度表現(IHC3+或FISH+)":
  exists (
    [MedicationRequest] MR
      where MR.intent = 'plan'
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and Cdg.code in CodeConcept.L01FD01
        )
        and Reusable."醫令類別為1"
  )
  and "條件1-1=HER2過度表現(IHC3+或FISH+)"


//條件1-2:曾接受過一次以上化學治療之轉移性乳癌病人

define "條件1-2-1=病摘應說明曾接受哪種化學治療":
    exists (
        [Claim] C
        where exists (
            C.diagnosis D
            where exists (
                D.type.text T
                where Matches(T.value, '(?i).*(化學治療).*')
            )
        )
    )

define "條件1-2-2=3個月內影像報告":
Reusable."HasRecentImageReport"("本次申請起始日期", 90)

define "條件1-2-3=癌症分期分數或結果為M>=1":
  exists (
    [Observation] O
      where exists (
        O.code.coding Cdg
          where Cdg.code = '399390009'
            and Cdg in CodeConcept.SNOMED
      )
        and O.value is not null
        and O.value is FHIR.string
        and Matches((O.value as FHIR.string).value, '.*M[^0].*')
  )

define "規則1-2-4=有檢查報告":
  exists (
    [DiagnosticReport] O2
    where exists (
      O2.code.coding Cdg
      where Cdg in CodeConcept.LOINC
      and Cdg.code in CodeConcept.MolecularReport
    )
  ) 

define "條件1-2-5=併用化學治療":
  exists (
    [MedicationRequest] MRPlan
    where MRPlan.intent = 'plan'
      and exists (
        MRPlan.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
          and Cdg.code in CodeConcept.L01FD01
      )
      and Reusable."HasValidTiming"(MRPlan)
      and exists (
        [MedicationRequest] MROrder
        where MROrder.intent = 'order'
          and exists (
            MROrder.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and Cdg.code in CodeConcept."併用化學治療法" 
          )
          and Reusable."HasValidTiming"(MROrder)
          and MROrder.dosageInstruction[0].timing.repeat.bounds is Period
          and (start of (MROrder.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
          and MRPlan.dosageInstruction[0].timing.repeat.bounds is Period
          and (start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
          and (start of (MROrder.dosageInstruction[0].timing.repeat.bounds as Period)) < (start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period))
      )
  )
  and Reusable."醫令類別為1"  


define "條件1-2=曾接受過一次以上化學治療之轉移性乳癌病人":
Reusable."ICD-10使用C50"
and "條件1-2-1=病摘應說明曾接受哪種化學治療"
and "條件1-2-3=癌症分期分數或結果為M>=1"
and "規則1-2-4=有檢查報告"
and "條件1-2-5=併用化學治療"
or "條件1-2-2=3個月內影像報告"

//規則1

define "規則1=單獨使用於治療腫瘤細胞上有HER2過度表現(IHC3+或FISH+)，曾接受過一次以上化學治療之轉移性乳癌病人":
"條件1-1=單獨使用於治療腫瘤細胞上有HER2過度表現(IHC3+或FISH+)" and "條件1-2=曾接受過一次以上化學治療之轉移性乳癌病人"


/*規則2*/

//2條件1:與paclitaxel或docetaxel併用

//2條件1-1:與paclitaxel併用
define "2條件1-1=與paclitaxel併用":
  Reusable."HasConcurrentMedicationOrder"(CodeConcept.L01FD01, CodeConcept.L01CD01)
  and Reusable."醫令類別為1"

//2條件1-2:與docetaxel併用
define "2條件1-2=與docetaxel併用":
  Reusable."HasConcurrentMedicationOrder"(CodeConcept.L01FD01, CodeConcept.L01CD02)
  and Reusable."醫令類別為1"

define "2條件1=與paclitaxel或docetaxel併用":
"2條件1-1=與paclitaxel併用" or "2條件1-2=與docetaxel併用"

//2條件2:使用於未曾接受過化學治療之轉移性乳癌病患
define "2條件2=未曾接受過化學治療":
  not exists (
    [MedicationRequest] NoBevacizumabMR
    where NoBevacizumabMR.intent = 'order'
    and exists (
      NoBevacizumabMR.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
      and Cdg.code in CodeConcept."併用化學治療法" 
    )
    and Reusable."HasValidTiming"(NoBevacizumabMR)
  )

define "2條件2=使用於未曾接受過化學治療之轉移性乳癌病患":
Reusable."ICD-10使用C50"
and "條件1-2-3=癌症分期分數或結果為M>=1"
and "2條件2=未曾接受過化學治療"
or ("條件1-2-2=3個月內影像報告" and "規則1-2-4=有檢查報告")

//條件2-3:且為HER2過度表現(IHC3+或FISH+)者
define "條件2-3=且為HER2過度表現(IHC3+或FISH+)者":
"條件1-1=HER2過度表現(IHC3+或FISH+)"

define "規則2=與paclitaxel或docetaxel併用，使用於未曾接受過化學治療之轉移性乳癌病患，且為HER2過度表現(IHC3+或FISH+)者":
"2條件1=與paclitaxel或docetaxel併用"
and "2條件2=使用於未曾接受過化學治療之轉移性乳癌病患"
and "條件2-3=且為HER2過度表現(IHC3+或FISH+)者"

/*規則3*/

//3條件1:轉移性乳癌
define "3條件1=轉移性乳癌":
Reusable."ICD-10使用C50"
and "條件1-2-3=癌症分期分數或結果為M>=1"
and "條件1-2-2=3個月內影像報告" 
and "規則1-2-4=有檢查報告"

//3條件2:HER2過度表現之病人
define "3條件2=HER2過度表現之病人":
"條件2-3=且為HER2過度表現(IHC3+或FISH+)者"

// 本次申請紀錄（以最新一筆申請作為本次申請）
define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.L01FD01)

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

//3條件3:僅限先前未使用過本藥品者方可使用

define "3條件3=僅限先前未使用過本藥品者方可使用":
  not Reusable."HasPriorMedicationUse"(CodeConcept.L01FD01, CodeConcept.L01FD01)

define "規則3=轉移性乳癌且HER2過度表現之病人，僅限先前未使用過本藥品者方可使用":
"3條件1=轉移性乳癌"
and "3條件2=HER2過度表現之病人"
and "3條件3=僅限先前未使用過本藥品者方可使用"


/*規則4*/

//4條件1:若先前使用過docetaxel及pertuzumab與trastuzumab併用達18個月上限仍未惡化者，得再次申請本藥品
//4條件1-1
define "4條件1-1=先前使用過docetaxel及pertuzumab與trastuzumab併用達18個月上限":
  exists (
    [MedicationRequest] MRPlan
    where MRPlan.intent = 'plan'
      and exists (
        MRPlan.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
          and Cdg.code in CodeConcept.L01FD01
      )
      and Reusable."HasValidTiming"(MRPlan)

      // 先前曾使用 docetaxel
      and exists (
        [MedicationRequest] MRDocetaxel
        where MRDocetaxel.intent in { 'plan', 'order' }
          and exists (
            MRDocetaxel.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and Cdg.code in CodeConcept.L01CD02
          )
          and Reusable."HasValidTiming"(MRDocetaxel)
          and (start of (MRDocetaxel.dosageInstruction[0].timing.repeat.bounds as Period))
            < (start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period))
          and (end of (MRDocetaxel.dosageInstruction[0].timing.repeat.bounds as Period))
            < (start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period))
      )

      // 先前曾使用 pertuzumab
      and exists (
        [MedicationRequest] MRPertuzumab
        where MRPertuzumab.intent in { 'plan', 'order' }
          and exists (
            MRPertuzumab.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and Cdg.code in CodeConcept.L01FD02
          )
          and Reusable."HasValidTiming"(MRPertuzumab)
          and (start of (MRPertuzumab.dosageInstruction[0].timing.repeat.bounds as Period))
            < (start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period))
          and (end of (MRPertuzumab.dosageInstruction[0].timing.repeat.bounds as Period))
            < (start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period))
      )

      // 先前曾使用 trastuzumab，代表 pertuzumab 與 trastuzumab 併用路徑
      and exists (
        [MedicationRequest] MRTrastuzumab
        where MRTrastuzumab.intent in { 'plan', 'order' }
          and exists (
            MRTrastuzumab.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and Cdg.code in CodeConcept.L01FD01
          )
          and Reusable."HasValidTiming"(MRTrastuzumab)
          and (start of (MRTrastuzumab.dosageInstruction[0].timing.repeat.bounds as Period))
            < (start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period))
          and (end of (MRTrastuzumab.dosageInstruction[0].timing.repeat.bounds as Period))
            < (start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period))
      )
      // 既往 docetaxel / pertuzumab / trastuzumab 併用療程長度上限
      and Sum(
        [MedicationRequest] MRPrior
          where MRPrior.intent in { 'plan', 'order' }
            and exists (
              MRPrior.medication.coding Cdg
                where Cdg in CodeConcept.NHIMedication
                  and (
                    Cdg.code in CodeConcept.L01CD02
                    or Cdg.code in CodeConcept.L01FD02
                    or Cdg.code in CodeConcept.L01FD01
                  )
            )
            and Reusable."HasValidTiming"(MRPrior)
            and (start of (MRPrior.dosageInstruction[0].timing.repeat.bounds as Period))
              < (start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period))
            and (end of (MRPrior.dosageInstruction[0].timing.repeat.bounds as Period))
              < (start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period))
          return all
            difference in days between
              FHIRHelpers.ToDateTime(
                (MRPrior.dosageInstruction[0].timing.repeat.bounds as Period).start
              )
              and FHIRHelpers.ToDateTime(
                (MRPrior.dosageInstruction[0].timing.repeat.bounds as Period).end
              )
      ) = 126
  )
  and Reusable."醫令類別為1"

//4條件1-2
define "4條件1-2=病摘應說明先前使用過docetaxel及pertuzumab與trastuzumab併用達18個月上限仍未惡化":
    exists (
        [Claim] C
        where exists (
            C.diagnosis D
            where exists (
                D.type.text T
                where Matches(T.value, '(?i).*(使用過docetaxel及pertuzumab與trastuzumab併用達18個月上限仍未惡化).*')
            )
        )
    )

define "4條件1=若先前使用過docetaxel及pertuzumab與trastuzumab併用達18個月上限仍未惡化者，得再次申請本藥品":
"4條件1-1=先前使用過docetaxel及pertuzumab與trastuzumab併用達18個月上限"
and "4條件1-2=病摘應說明先前使用過docetaxel及pertuzumab與trastuzumab併用達18個月上限仍未惡化"
and "條件1-2-2=3個月內影像報告" 

//4條件2:若先前使用過docetaxel及pertuzumab與trastuzumab皮下注射複方製劑(如Phesgo)併用達18個月上限仍未惡化者，得再次申請本藥品
//4條件2-1
define "4條件2-1=先前使用過docetaxel及pertuzumab與trastuzumab皮下注射複方製劑(如Phesgo)併用達18個月上限":
  exists (
    [MedicationRequest] MRPlan
    where MRPlan.intent = 'plan'
      and exists (
        MRPlan.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
          and Cdg.code in CodeConcept.L01FD01
      )
      and Reusable."HasValidTiming"(MRPlan)

      // 先前曾使用 docetaxel
      and exists (
        [MedicationRequest] MRDocetaxel
        where MRDocetaxel.intent in { 'plan', 'order' }
          and exists (
            MRDocetaxel.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and Cdg.code in CodeConcept.L01CD02
          )
          and Reusable."HasValidTiming"(MRDocetaxel)
          and (start of (MRDocetaxel.dosageInstruction[0].timing.repeat.bounds as Period))
            < (start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period))
          and (end of (MRDocetaxel.dosageInstruction[0].timing.repeat.bounds as Period))
            < (start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period))
      )

      // 先前曾使用 pertuzumab與trastuzumab皮下注射複方製劑
      and exists (
        [MedicationRequest] MRPertuzumab
        where MRPertuzumab.intent in { 'plan', 'order' }
          and exists (
            MRPertuzumab.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and Cdg.code in CodeConcept.L01FY01
          )
          and Reusable."HasValidTiming"(MRPertuzumab)
          and (start of (MRPertuzumab.dosageInstruction[0].timing.repeat.bounds as Period))
            < (start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period))
          and (end of (MRPertuzumab.dosageInstruction[0].timing.repeat.bounds as Period))
            < (start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period))
      )

      // 既往 docetaxel / pertuzumab / trastuzumab 併用療程長度上限
      and Sum(
        [MedicationRequest] MRPrior
          where MRPrior.intent in { 'plan', 'order' }
            and exists (
              MRPrior.medication.coding Cdg
                where Cdg in CodeConcept.NHIMedication
                  and (
                    Cdg.code in CodeConcept.L01CD02
                    or Cdg.code in CodeConcept.L01FY01
                  )
            )
            and Reusable."HasValidTiming"(MRPrior)
            and (start of (MRPrior.dosageInstruction[0].timing.repeat.bounds as Period))
              < (start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period))
            and (end of (MRPrior.dosageInstruction[0].timing.repeat.bounds as Period))
              < (start of (MRPlan.dosageInstruction[0].timing.repeat.bounds as Period))
          return all
            difference in days between
              FHIRHelpers.ToDateTime(
                (MRPrior.dosageInstruction[0].timing.repeat.bounds as Period).start
              )
              and FHIRHelpers.ToDateTime(
                (MRPrior.dosageInstruction[0].timing.repeat.bounds as Period).end
              )
      ) = 126
  )
  and Reusable."醫令類別為1"

//4條件2-2
define "4條件2-2=病摘應說明先前使用過docetaxel及pertuzumab與trastuzumab皮下注射複方製劑(如Phesgo)併用達18個月上限未惡化":
    exists (
        [Claim] C
        where exists (
            C.diagnosis D
            where exists (
                D.type.text T
                where Matches(T.value, '(?i).*(使用過docetaxel及pertuzumab與trastuzumab皮下注射複方製劑併用達18個月上限未惡化).*')
            )
        )
    )

define "4條件2=若先前使用過docetaxel及pertuzumab與trastuzumab併用達18個月上限仍未惡化者，得再次申請本藥品":
"4條件2-1=先前使用過docetaxel及pertuzumab與trastuzumab皮下注射複方製劑(如Phesgo)併用達18個月上限"
and "4條件2-2=病摘應說明先前使用過docetaxel及pertuzumab與trastuzumab皮下注射複方製劑(如Phesgo)併用達18個月上限未惡化"
and "條件1-2-2=3個月內影像報告" 

/*規則4*/
define "規則4=若先前使用過docetaxel及pertuzumab與trastuzumab併用或docetaxel及pertuzumab與trastuzumab皮下注射複方製劑(如Phesgo)併用達18個月上限仍未惡化者，得再次申請本藥品":
"4條件1=若先前使用過docetaxel及pertuzumab與trastuzumab併用達18個月上限仍未惡化者，得再次申請本藥品"
or "4條件2=若先前使用過docetaxel及pertuzumab與trastuzumab併用達18個月上限仍未惡化者，得再次申請本藥品"

//主要規定一
define "主要規定一":
"規則1=單獨使用於治療腫瘤細胞上有HER2過度表現(IHC3+或FISH+)，曾接受過一次以上化學治療之轉移性乳癌病人"
or "規則2=與paclitaxel或docetaxel併用，使用於未曾接受過化學治療之轉移性乳癌病患，且為HER2過度表現(IHC3+或FISH+)者"
or "規則3=轉移性乳癌且HER2過度表現之病人，僅限先前未使用過本藥品者方可使用"
or "規則4=若先前使用過docetaxel及pertuzumab與trastuzumab併用或docetaxel及pertuzumab與trastuzumab皮下注射複方製劑(如Phesgo)併用達18個月上限仍未惡化者，得再次申請本藥品"



//============================================
// 主要規定二：續用條件－治療持續給付
//============================================


//條件1:核准後每18週須檢附療效評估資料再次申請，若疾病有惡化情形即不應再行申請



// 前次申請紀錄（本次申請之前最近一次的申請）
define "前次申請紀錄":
  Reusable."LatestMedicationPlanBefore"(CodeConcept.L01FD01, "本次申請起始日期")

// 檢查本次申請療程長度是否在18週內
define "規則1-1=每18週須再次申請並檢附療效評估資料":
  Reusable."醫令類別為1" 
  and Reusable."續用註記為2"
  and "本次申請紀錄" is not null
  and (
    // 計算本次申請起始日期到終止日期的天數差異
    difference in days between
      FHIRHelpers.ToDateTime(("本次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).start)
      and FHIRHelpers.ToDateTime(("本次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).end)
  ) = 126  // 18週 = 126天


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
and "規則1-1=每18週須再次申請並檢附療效評估資料"
and "規則1-2=疾病有惡化情形須停止使用"


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and (
    "規則1=單獨使用於治療腫瘤細胞上有HER2過度表現(IHC3+或FISH+)，曾接受過一次以上化學治療之轉移性乳癌病人" or
    "規則2=與paclitaxel或docetaxel併用，使用於未曾接受過化學治療之轉移性乳癌病患，且為HER2過度表現(IHC3+或FISH+)者" or
    "規則3=轉移性乳癌且HER2過度表現之病人，僅限先前未使用過本藥品者方可使用" or
    "規則4=若先前使用過docetaxel及pertuzumab與trastuzumab併用或docetaxel及pertuzumab與trastuzumab皮下注射複方製劑(如Phesgo)併用達18個月上限仍未惡化者，得再次申請本藥品"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "規則1=單獨使用於治療腫瘤細胞上有HER2過度表現(IHC3+或FISH+)，曾接受過一次以上化學治療之轉移性乳癌病人"
           then '● 規則1：單獨使用，HER2過度表現(IHC3+或FISH+)，曾接受過化學治療之轉移性乳癌病人\n' else '') +
         (if "條件1-1=HER2過度表現(IHC3+或FISH+)"
           then '  ● 條件1-1：HER2過度表現(IHC3+或FISH+)\n' else '') +
         (if "條件1-2-1=病摘應說明曾接受哪種化學治療"
           then '  ● 條件1-2-1：病摘已說明曾接受之化學治療\n' else '') +
         (if "條件1-2-3=癌症分期分數或結果為M>=1"
           then '  ● 條件1-2-3：癌症分期M≥1(轉移性)\n' else '') +
         (if "規則1-2-4=有檢查報告"
           then '  ● 條件1-2-4：已提供基因/病理檢查報告\n' else '') +
         (if "條件1-2-2=3個月內影像報告"
           then '  ● 條件1-2-2：已提供3個月內影像報告\n' else '') +
         (if "規則2=與paclitaxel或docetaxel併用，使用於未曾接受過化學治療之轉移性乳癌病患，且為HER2過度表現(IHC3+或FISH+)者"
           then '● 規則2：與paclitaxel或docetaxel併用，未曾接受過化學治療，HER2過度表現(IHC3+或FISH+)\n' else '') +
         (if "2條件1=與paclitaxel或docetaxel併用"
           then '  ● 2條件1：已開立paclitaxel或docetaxel併用醫令\n' else '') +
         (if "2條件2=未曾接受過化學治療"
           then '  ● 2條件2：未曾接受過化學治療\n' else '') +
         (if "規則3=轉移性乳癌且HER2過度表現之病人，僅限先前未使用過本藥品者方可使用"
           then '● 規則3：轉移性乳癌，HER2過度表現，先前未使用過本藥品\n' else '') +
         (if "3條件3=僅限先前未使用過本藥品者方可使用"
           then '  ● 3條件3：先前未使用過本藥品\n' else '') +
         (if "規則4=若先前使用過docetaxel及pertuzumab與trastuzumab併用或docetaxel及pertuzumab與trastuzumab皮下注射複方製劑(如Phesgo)併用達18個月上限仍未惡化者，得再次申請本藥品"
           then '● 規則4：先前使用過docetaxel及pertuzumab與trastuzumab(或Phesgo)併用達18個月上限仍未惡化，得再次申請\n' else '') +
         (if "4條件1=若先前使用過docetaxel及pertuzumab與trastuzumab併用達18個月上限仍未惡化者，得再次申請本藥品"
           then '  ● 4條件1：先前使用過docetaxel及pertuzumab與trastuzumab併用達18個月上限仍未惡化\n' else '') +
         (if "4條件1-2=病摘應說明先前使用過docetaxel及pertuzumab與trastuzumab併用達18個月上限仍未惡化"
           then '  ● 4條件1-2：病摘已說明先前使用過相關藥品達18個月上限仍未惡化\n' else '') +
         (if "4條件2=若先前使用過docetaxel及pertuzumab與trastuzumab併用達18個月上限仍未惡化者，得再次申請本藥品"
           then '  ● 4條件2：先前使用過docetaxel及pertuzumab與trastuzumab皮下注射複方製劑(如Phesgo)達18個月上限仍未惡化\n' else '') +
         (if "4條件2-2=病摘應說明先前使用過docetaxel及pertuzumab與trastuzumab皮下注射複方製劑(如Phesgo)併用達18個月上限未惡化"
           then '  ● 4條件2-2：病摘已說明先前使用過Phesgo達18個月上限未惡化\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件
  (if Reusable."續用申請" and (
    "規則1-1=每18週須再次申請並檢附療效評估資料" or
    "規則1-2=疾病有惡化情形須停止使用"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if "規則1-1=每18週須再次申請並檢附療效評估資料"
           then '● 續用條件1：於18週內再次申請並檢附療效評估資料\n' else '') +
         (if "規則1-2=疾病有惡化情形須停止使用"
           then '● 續用條件2：已檢附前次治療後影像學報告，確認無惡化\n' else '') +
         '\n'
    else '')


//============================================
// 列出「不符合」項目判斷式 - 代碼或條件不符
//============================================

define function "不符合項目_代碼或條件不符"():
  // 主要規定一：共用代碼條件不符（適用所有規則）
  (if Reusable."初次申請" and (
    not Reusable."ICD-10使用C50" or
    not "條件1-1=HER2過度表現(IHC3+或FISH+)" or
    not "條件1-2-3=癌症分期分數或結果為M>=1"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not Reusable."ICD-10使用C50"
           then '▲ ICD代碼檢核：主要疾病之ICD代碼未使用C50\n' else '') +
         (if not "條件1-1=HER2過度表現(IHC3+或FISH+)"
           then '▲ 條件1-1：HER2非過度表現(非IHC3+或FISH+)\n' else '') +
         (if not "條件1-2-3=癌症分期分數或結果為M>=1"
           then '▲ 條件1-2-3：癌症分期未達轉移性(M<1)\n' else '') +
         '\n'
    else '') +

  // 規則2 ：已有 paclitaxel/docetaxel 併用醫令，但曾接受過化學治療
  (if Reusable."初次申請"
    and "2條件1=與paclitaxel或docetaxel併用"
    and not "2條件2=未曾接受過化學治療"
    then '<規則2：與paclitaxel或docetaxel併用>\n' +
         '▲ 2條件2：病患曾接受過化學治療，不符合規則2未曾接受化療之條件\n' +
         '\n'
    else '') +

  // 規則3 ：轉移性乳癌且HER2過度表現，但先前已使用過本藥品
  (if Reusable."初次申請"
    and "3條件1=轉移性乳癌"
    and "3條件2=HER2過度表現之病人"
    and not "3條件3=僅限先前未使用過本藥品者方可使用"
    then '<規則3：轉移性乳癌且HER2過度表現>\n' +
         '▲ 3條件3：病患先前已使用過本藥品，不符合規則3之資格\n' +
         '\n'
    else '')


//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 規則1 ：需說明化學治療史
  (if Reusable."初次申請"
    and "條件1-1=單獨使用於治療腫瘤細胞上有HER2過度表現(IHC3+或FISH+)"
    and not "條件1-2-1=病摘應說明曾接受哪種化學治療"
    then '<規則1：單獨使用，曾接受過化學治療>\n' +
         '▲ 條件1-2-1：病摘未說明曾接受之化學治療種類\n' +
         '\n'
    else '') +

  // 共用：影像報告及基因/病理檢查報告（規則1/2/3/4 皆需）
  (if Reusable."初次申請" and (
    not "條件1-2-2=3個月內影像報告" or
    not "規則1-2-4=有檢查報告"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "條件1-2-2=3個月內影像報告"
           then '▲ 條件1-2-2：未提供3個月內之影像報告\n' else '') +
         (if not "規則1-2-4=有檢查報告"
           then '▲ 條件1-2-4：未提供基因或病理檢查報告\n' else '') +
         '\n'
    else '') +

  // 規則4：docetaxel及pertuzumab與trastuzumab併用達18個月
  (if Reusable."初次申請"
    and "4條件1-1=先前使用過docetaxel及pertuzumab與trastuzumab併用達18個月上限"
    and not "4條件1-2=病摘應說明先前使用過docetaxel及pertuzumab與trastuzumab併用達18個月上限仍未惡化"
    then '<規則4路徑1：docetaxel及pertuzumab與trastuzumab併用>\n' +
         '▲ 4條件1-2：病摘未說明先前使用過docetaxel及pertuzumab與trastuzumab併用達18個月上限仍未惡化\n' +
         '\n'
    else '') +

  // 規則4：Phesgo併用達18個月
  (if Reusable."初次申請"
    and "4條件2-1=先前使用過docetaxel及pertuzumab與trastuzumab皮下注射複方製劑(如Phesgo)併用達18個月上限"
    and not "4條件2-2=病摘應說明先前使用過docetaxel及pertuzumab與trastuzumab皮下注射複方製劑(如Phesgo)併用達18個月上限未惡化"
    then '<規則4路徑2：docetaxel及Phesgo併用>\n' +
         '▲ 4條件2-2：病摘未說明先前使用過Phesgo達18個月上限未惡化\n' +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (
    not "規則1-1=每18週須再次申請並檢附療效評估資料" or
    not "規則1-2=疾病有惡化情形須停止使用"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if not "規則1-1=每18週須再次申請並檢附療效評估資料"
           then '▲ 續用條件1：未於18週內再次申請或申請期間不符126天\n' else '') +
         (if not "規則1-2=疾病有惡化情形須停止使用"
           then '▲ 續用條件2：未提供前次治療後影像學報告\n' else '') +
         '\n'
    else '')


//============================================
// 審核結果
//============================================

define "乳癌Trastuzumab3申請結果_布林":
  case
    when Reusable."初次申請" then "主要規定一"
    when Reusable."續用申請" then "主要規定二"
    else false
  end

define "乳癌Trastuzumab3申請之CQL檢核結果":
  if (Reusable."初次申請" and "主要規定一")
  then '✓通過：初次使用－轉移性乳癌Trastuzumab用藥申請'

  else if (Reusable."續用申請" and "主要規定二")
  then '✓通過：續用－轉移性乳癌Trastuzumab用藥申請'

  else if Reusable."初次申請"
  then '✖不通過：初次使用－轉移性乳癌Trastuzumab用藥申請'

  else if Reusable."續用申請"
  then '✖不通過：續用－轉移性乳癌Trastuzumab用藥申請'

  else '✖不通過：無法判定申請類型－轉移性乳癌Trastuzumab用藥申請'


//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 轉移性乳癌之Trastuzumab申請審核報告 ===\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  (if not "乳癌Trastuzumab3申請結果_布林"
    then
      '\n【▲不符合項目 - 代碼或條件不符】\n' +
      (if "不符合項目_代碼或條件不符"() = '' then '無\n' else "不符合項目_代碼或條件不符"()) +
      '\n【▲不符合項目 - 必要資料未填寫】\n' +
      (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"())
    else '') +
  '\n【申請結果】\n' +
  "乳癌Trastuzumab3申請之CQL檢核結果" +
  '\n===============================================\n'
