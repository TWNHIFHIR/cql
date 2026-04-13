//早期乳癌（二線治療）_Trastuzumab Deruxtecan給付規定
library BCTrastuzumabDeruxtecanRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include BCCodeConcept version '1.0.0' called CodeConcept

include BCReusable version '1.0.0' called Reusable

context Patient


//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/

//1條件1:單獨使用於具HER2過度表現(IHC3+或FISH+)之轉移性乳癌病人作為二線治療
define "ICD代碼檢核_布林值": Reusable."ICD-10使用C50"

define "醫令類別為1_布林值": Reusable."醫令類別為1"

define "用藥線別檢核_布林值": Reusable."用藥線別=2"

define "3個月內影像報告":
Reusable."HasRecentImageReport"("本次申請起始日期", 90)


define "癌症分期分數或結果為M>=1":
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


define "3個月內有檢查報告":
Reusable."HasRecentMolecularReport"("本次申請起始日期", 90)


define "檢驗檢查-HER2過度表現(IHC3+或FISH+)":
  Reusable."HasHER2OverexpressionTest"

define "基因檢測-HER2過度表現(IHC3+或FISH+)":
  Reusable."HasHER2OverexpressionGene"

define "HER2過度表現(IHC3+或FISH+)":
  "檢驗檢查-HER2過度表現(IHC3+或FISH+)"
  or "基因檢測-HER2過度表現(IHC3+或FISH+)"

define "1條件1=單獨使用於具HER2過度表現(IHC3+或FISH+)之轉移性乳癌病人作為二線治療":
Reusable."ICD-10使用C50"
and Reusable."醫令類別為1"
and Reusable."用藥線別=2"
and "癌症分期分數或結果為M>=1"
and "HER2過度表現(IHC3+或FISH+)"
and (
  (not "3個月內影像報告" and not "3個月內有檢查報告")
  or ("3個月內影像報告" and "3個月內有檢查報告")
)


//1條件2:同時符合下列情形：
//(1)之前分別接受過 trastuzumab 與一種taxane 藥物治療，或其合併療法，或pertuzumab 與trastuzumab 與一種taxane藥物治療。
//(2)之前已經接受過轉移性癌症治療，或在輔助療法治療期間或完成治療後6 個月內癌症復發。
//(3)合併有主要臟器(不包含骨及軟組織)轉移。


//1條件2-1:之前分別接受過trastuzumab與一種taxane藥物治療，或其合併療法，或pertuzumab與trastuzumab與一種taxane藥物治療
//1條件2-1-1:trastuzumab 與一種taxane 藥物治療
define "歷史trastuzumab":
  exists (
    [MedicationRequest] MR
      where MR.intent = 'order'
        and (MR.status is null or MR.status in { 'active', 'completed' })
        and exists MR.dosageInstruction
        and MR.dosageInstruction[0].timing.repeat.bounds is Period
        and start of (MR.dosageInstruction[0].timing.repeat.bounds as Period) is not null
        and start of (MR.dosageInstruction[0].timing.repeat.bounds as Period) < "本次申請起始日期"
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and Cdg.code in CodeConcept.L01FD01
        )
  )


define "歷史Docetaxel":
  exists (
    [MedicationRequest] MR
      where MR.intent = 'order'
        and (MR.status is null or MR.status in { 'active', 'completed' })
        and exists MR.dosageInstruction
        and MR.dosageInstruction[0].timing.repeat.bounds is Period
        and start of (MR.dosageInstruction[0].timing.repeat.bounds as Period) is not null
        and start of (MR.dosageInstruction[0].timing.repeat.bounds as Period) < "本次申請起始日期"
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and Cdg.code in CodeConcept.L01CD02
        )
  )

define "歷史Paclitaxel":
  exists (
    [MedicationRequest] MR
      where MR.intent = 'order'
        and (MR.status is null or MR.status in { 'active', 'completed' })
        and exists MR.dosageInstruction
        and MR.dosageInstruction[0].timing.repeat.bounds is Period
        and start of (MR.dosageInstruction[0].timing.repeat.bounds as Period) is not null
        and start of (MR.dosageInstruction[0].timing.repeat.bounds as Period) < "本次申請起始日期"
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and Cdg.code in CodeConcept.L01CD01
        )
  )


define "1條件2-1-1=trastuzumab與一種taxane藥物治療":
  "歷史trastuzumab" or "歷史Docetaxel" or "歷史Paclitaxel"


//1條件2-1-2:trastuzumab 與一種taxane合併療法
define "歷史taxane":
  exists (
    [MedicationRequest] MR
      where MR.intent = 'order'
        and (MR.status is null or MR.status in { 'active', 'completed' })
        and exists MR.dosageInstruction
        and MR.dosageInstruction[0].timing.repeat.bounds is Period
        and start of (MR.dosageInstruction[0].timing.repeat.bounds as Period) is not null
        and start of (MR.dosageInstruction[0].timing.repeat.bounds as Period) < "本次申請起始日期"
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and (
                Cdg.code in CodeConcept.L01CD02
                or Cdg.code in CodeConcept.L01CD01
              )
        )
  )

define "1條件2-1-2=trastuzumab 與一種taxane合併療法":
  "歷史trastuzumab" and "歷史taxane"

//1條件2-1-3:pertuzumab 與trastuzumab 與一種taxane藥物治療
define "1條件2-1-3=pertuzumab與trastuzumab與一種taxane藥物治療":
  exists (
    from
      [MedicationRequest] P,
      [MedicationRequest] HT,
      [MedicationRequest] TX
    where P.intent = 'order'
      and HT.intent = 'order'
      and TX.intent = 'order'
      and (P.status is null or P.status in { 'active', 'completed' })
      and (HT.status is null or HT.status in { 'active', 'completed' })
      and (TX.status is null or TX.status in { 'active', 'completed' })
      and exists P.dosageInstruction
      and exists HT.dosageInstruction
      and exists TX.dosageInstruction
      and P.dosageInstruction[0].timing.repeat.bounds is Period
      and HT.dosageInstruction[0].timing.repeat.bounds is Period
      and TX.dosageInstruction[0].timing.repeat.bounds is Period
      and start of (P.dosageInstruction[0].timing.repeat.bounds as Period) is not null
      and start of (HT.dosageInstruction[0].timing.repeat.bounds as Period) is not null
      and start of (TX.dosageInstruction[0].timing.repeat.bounds as Period) is not null
      and start of (P.dosageInstruction[0].timing.repeat.bounds as Period) < "本次申請起始日期"
      and start of (HT.dosageInstruction[0].timing.repeat.bounds as Period) < "本次申請起始日期"
      and start of (TX.dosageInstruction[0].timing.repeat.bounds as Period) < "本次申請起始日期"
      and exists (
        P.medication.coding C1
          where C1 in CodeConcept.NHIMedication
            and C1.code in CodeConcept.L01FD02
      )
      and exists (
        HT.medication.coding C2
          where C2 in CodeConcept.NHIMedication
            and (
              C2.code in CodeConcept.L01FD01
              or C2.code in CodeConcept.L01FY01
            )
      )
      and exists (
        TX.medication.coding C3
          where C3 in CodeConcept.NHIMedication
            and (
              C3.code in CodeConcept.L01CD02
              or C3.code in CodeConcept.L01CD01
            )
      )
  )

define "1條件2-1=之前分別接受過trastuzumab與一種taxane藥物治療，或其合併療法，或pertuzumab與trastuzumab與一種taxane藥物治療":
"1條件2-1-1=trastuzumab與一種taxane藥物治療"
or "1條件2-1-2=trastuzumab 與一種taxane合併療法"
or "1條件2-1-3=pertuzumab與trastuzumab與一種taxane藥物治療"

//1條件2-2:之前已經接受過轉移性癌症治療，或在輔助療法治療期間或完成治療後6個月內癌症復發

//1條件2-2-1:之前已經接受過轉移性癌症治療
define "1條件2-2-1=之前已經接受過轉移性癌症治療":
    exists (
        [Claim] C
        where exists (
            C.diagnosis D
            where exists (
                D.type.text T
                where Matches(T.value, '(?i).*(已經接受過轉移性癌症治療).*')
            )
        )
    )

//1條件2-2-2:在輔助療法治療期間癌症復發
define "1條件2-2-2=在輔助療法治療期間癌症復發":
    exists (
        [Claim] C
        where exists (
            C.diagnosis D
            where exists (
                D.type.text T
                where Matches(T.value, '(?i).*(在輔助療法治療期間癌症復發).*')
            )
        )
    )

//1條件2-2-3:在完成治療後6個月內癌症復發
define "1條件2-2-3=在完成治療後6個月內癌症復發":
    exists (
        [Claim] C
        where exists (
            C.diagnosis D
            where exists (
                D.type.text T
                where Matches(T.value, '(?i).*(在完成治療後6個月內癌症復發).*')
            )
        )
    )

define "1條件2-2=之前已經接受過轉移性癌症治療，或在輔助療法治療期間或完成治療後6個月內癌症復發":
"1條件2-2-1=之前已經接受過轉移性癌症治療"
or "1條件2-2-2=在輔助療法治療期間癌症復發"
or "1條件2-2-3=在完成治療後6個月內癌症復發"

//
//1條件2-3:合併有主要臟器(不包含骨及軟組織)轉移
define "1條件2-3=合併有主要臟器(不包含骨及軟組織)轉移":
    exists (
        [Claim] C
        where exists (
            C.diagnosis D
            where exists (
                D.type.text T
                where Matches(T.value, '(?i).*(轉移臟器).*')
            )
        )
    )
    and "癌症分期分數或結果為M>=1"
    and "3個月內影像報告"

//1條件2
define "1條件2=同時符合下列情形":
"1條件2-1=之前分別接受過trastuzumab與一種taxane藥物治療，或其合併療法，或pertuzumab與trastuzumab與一種taxane藥物治療"
and "1條件2-2=之前已經接受過轉移性癌症治療，或在輔助療法治療期間或完成治療後6個月內癌症復發"
and "1條件2-3=合併有主要臟器(不包含骨及軟組織)轉移"

//主要規定一
define "主要規定一":
"1條件1=單獨使用於具HER2過度表現(IHC3+或FISH+)之轉移性乳癌病人作為二線治療"
and "1條件2=同時符合下列情形"


//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

//條件1:核准後每12週須檢附療效評估資料再次申請，若疾病有惡化情形即不應再行申請

// 本次申請紀錄（以最新一筆申請作為本次申請）
define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.L01FD04)

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

// 前次申請紀錄（本次申請之前最近一次的申請）
define "前次申請紀錄":
  Reusable."LatestMedicationPlanBefore"(CodeConcept.L01FD04, "本次申請起始日期")

// 檢查本次申請療程長度是否在12週內
define "規則1-1=每12週須再次申請並檢附療效評估資料":
  Reusable."醫令類別為1" 
  and Reusable."續用註記為2"
  and "本次申請紀錄" is not null
  and (
    // 計算本次申請起始日期到終止日期的天數差異
    difference in days between
      FHIRHelpers.ToDateTime(("本次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).start)
      and FHIRHelpers.ToDateTime(("本次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).end)
  ) <= 84  // 12週 = 84天


//條件2:疾病有惡化情形須停止使用

// 取得前次治療紀錄（最近一次已完成的治療）
define "前次治療紀錄":
  Reusable."LatestCompletedMedicationOrderBefore"(CodeConcept.L01FD04, "本次申請起始日期")

// 前次用藥開始日期
define "前次用藥開始日期":
  Reusable."GetStartTime"("前次治療紀錄")

// 規則1-2: 疾病有惡化情形須停止使用(續用須檢附前次治療後影像學報告)
define "規則1-2=疾病有惡化情形須停止使用":
  Reusable."HasImageReportBetweenPreviousTreatmentAndCurrentApply"(CodeConcept.L01FD04)

// 主要規定二
define "主要規定二":
Reusable."續用註記為2"
and Reusable."醫令類別為1"
and "本次申請紀錄" is not null
and "規則1-1=每12週須再次申請並檢附療效評估資料"
and "規則1-2=疾病有惡化情形須停止使用"


//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/

define "符合條件之本藥品處方":
  [MedicationRequest] MRTotal
    where (MRTotal.intent = 'plan')
      and (MRTotal.status is null or MRTotal.status in { 'active', 'completed', 'on-hold' })
      and exists MRTotal.dosageInstruction
      and MRTotal.dosageInstruction[0].timing.repeat.bounds is Period
      and start of (MRTotal.dosageInstruction[0].timing.repeat.bounds as Period) is not null
      and end of (MRTotal.dosageInstruction[0].timing.repeat.bounds as Period) is not null
      and MRTotal.dosageInstruction[0].timing.repeat.period = 3
      and MRTotal.dosageInstruction[0].timing.repeat.periodUnit.value = 'wk'
      and exists (
        MRTotal.medication.coding Cdg
          where Cdg in CodeConcept.NHIMedication
            and Cdg.code in CodeConcept.L01FD04
      )

define "規則1=每位病人至多給付18個療程為上限":
  Sum(
    "符合條件之本藥品處方" MRTotal
      return
        duration in days between
          start of (MRTotal.dosageInstruction[0].timing.repeat.bounds as Period)
          and end of (MRTotal.dosageInstruction[0].timing.repeat.bounds as Period)
  ) <= 378

/*規則2*/
define "曾使用Trastuzumab emtansine":
  Reusable."HasMedicationUse"(CodeConcept.L01FD03)

define "曾使用lapatinib":
  Reusable."HasMedicationUse"(CodeConcept.L01EH01)

define "曾使用trastuzumab deruxtecan":
  Reusable."HasMedicationUse"(CodeConcept.L01FD04)

define "規則2=Trastuzumab emtansine、lapatinib和trastuzumab deruxtecan僅能擇一給付，不得互換":
  not (
    ("曾使用Trastuzumab emtansine" and "曾使用lapatinib")
    or ("曾使用Trastuzumab emtansine" and "曾使用trastuzumab deruxtecan")
    or ("曾使用lapatinib" and "曾使用trastuzumab deruxtecan")
  )

//主要規定三
define "主要規定三":
"規則1=每位病人至多給付18個療程為上限"
and "規則2=Trastuzumab emtansine、lapatinib和trastuzumab deruxtecan僅能擇一給付，不得互換"


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and (
    "1條件1=單獨使用於具HER2過度表現(IHC3+或FISH+)之轉移性乳癌病人作為二線治療" or
    "1條件2=同時符合下列情形"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if Reusable."ICD-10使用C50"
           then '● 條件1(ICD)：主要疾病ICD代碼使用C50\n' else '') +
         (if Reusable."醫令類別為1"
           then '● 條件1(醫令)：醫令類別為1(事前審查)\n' else '') +
         (if Reusable."用藥線別=2"
           then '● 條件1(線別)：用藥線別為第二線\n' else '') +
         (if "癌症分期分數或結果為M>=1"
           then '● 條件1(分期)：癌症分期M≥1，確認為轉移性乳癌\n' else '') +
         (if "HER2過度表現(IHC3+或FISH+)"
           then '● 條件1(HER2)：HER2過度表現(IHC3+或FISH+)\n' else '') +
         (if "3個月內影像報告" and "3個月內有檢查報告"
           then '● 條件1(報告)：已同時提供3個月內影像報告及分子檢查報告\n' else '') +
         (if not "3個月內影像報告" and not "3個月內有檢查報告"
           then '● 條件1(報告)：無需附上3個月內影像報告及分子檢查報告\n' else '') +
         (if "1條件2-1=之前分別接受過trastuzumab與一種taxane藥物治療，或其合併療法，或pertuzumab與trastuzumab與一種taxane藥物治療"
           then '● 條件2-1：曾接受trastuzumab+taxane治療，或其合併療法，或pertuzumab+trastuzumab+taxane\n' else '') +
         (if "1條件2-2=之前已經接受過轉移性癌症治療，或在輔助療法治療期間或完成治療後6個月內癌症復發"
           then '● 條件2-2：曾接受轉移性癌症治療，或輔助療法中/完成後6個月內癌症復發\n' else '') +
         (if "1條件2-3=合併有主要臟器(不包含骨及軟組織)轉移"
           then '● 條件2-3：合併有主要臟器(不含骨及軟組織)轉移\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件
  (if Reusable."續用申請" and (
    "規則1-1=每12週須再次申請並檢附療效評估資料" or
    "規則1-2=疾病有惡化情形須停止使用"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if "規則1-1=每12週須再次申請並檢附療效評估資料"
           then '● 續用條件1：於12週內再次申請並檢附療效評估資料\n' else '') +
         (if "規則1-2=疾病有惡化情形須停止使用"
           then '● 續用條件2：已檢附前次治療後影像學報告，確認無惡化\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則
  (if "規則1=每位病人至多給付18個療程為上限" or "規則2=Trastuzumab emtansine、lapatinib和trastuzumab deruxtecan僅能擇一給付，不得互換"
    then '<主要規定三：藥品使用規則>\n' +
         (if "規則1=每位病人至多給付18個療程為上限"
           then '● 規則1：本藥品使用療程符合18個療程上限(≤378天)\n' else '') +
         (if "規則2=Trastuzumab emtansine、lapatinib和trastuzumab deruxtecan僅能擇一給付，不得互換"
           then '● 規則2：未與Trastuzumab emtansine或lapatinib交替或混用，符合擇一給付規定\n' else '')
    else '')


//============================================
// 列出「不符合」項目判斷式 - 代碼或條件不符
//============================================

define function "不符合項目_代碼或條件不符"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if Reusable."初次申請" and (
    not Reusable."ICD-10使用C50" or
    not Reusable."醫令類別為1" or
    not Reusable."用藥線別=2" or
    not "癌症分期分數或結果為M>=1" or
    not "HER2過度表現(IHC3+或FISH+)" or
    not "1條件2-1=之前分別接受過trastuzumab與一種taxane藥物治療，或其合併療法，或pertuzumab與trastuzumab與一種taxane藥物治療" or
    not "1條件2-2=之前已經接受過轉移性癌症治療，或在輔助療法治療期間或完成治療後6個月內癌症復發" or
    not "1條件2-3=合併有主要臟器(不包含骨及軟組織)轉移"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not Reusable."ICD-10使用C50"
           then '▲ ICD代碼檢核：主要疾病之ICD代碼未使用C50\n' else '') +
         (if not Reusable."醫令類別為1"
           then '▲ 條件1(醫令)：醫令類別非1，非事前審查申請\n' else '') +
         (if not Reusable."用藥線別=2"
           then '▲ 條件1(線別)：用藥線別非第二線\n' else '') +
         (if not "癌症分期分數或結果為M>=1"
           then '▲ 條件1(分期)：癌症分期M<1，未確認為轉移性乳癌\n' else '') +
         (if not "HER2過度表現(IHC3+或FISH+)"
           then '▲ 條件1(HER2)：HER2非過度表現(非IHC3+或FISH+)\n' else '') +
         (if not "1條件2-1=之前分別接受過trastuzumab與一種taxane藥物治療，或其合併療法，或pertuzumab與trastuzumab與一種taxane藥物治療"
           then '▲ 條件2-1：無trastuzumab與taxane之治療紀錄(含合併療法及pertuzumab三藥合療)\n' else '') +
         (if not "1條件2-2=之前已經接受過轉移性癌症治療，或在輔助療法治療期間或完成治療後6個月內癌症復發"
           then '▲ 條件2-2：不符合轉移性癌症治療史或復發時程條件\n' else '') +
         (if not "1條件2-3=合併有主要臟器(不包含骨及軟組織)轉移"
           then '▲ 條件2-3：未確認合併有主要臟器(不含骨及軟組織)轉移，或癌症分期M<1\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 療程超標或條件不符
  (if not "規則1=每位病人至多給付18個療程為上限"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則1：本藥品使用療程超過18個療程上限(378天)\n' + '\n'
    else '') +

  (if not "規則2=Trastuzumab emtansine、lapatinib和trastuzumab deruxtecan僅能擇一給付，不得互換"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則2：曾與Trastuzumab emtansine或lapatinib交替或混用，違反擇一給付規定\n' + '\n'
    else '')


//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
    not "HER2過度表現(IHC3+或FISH+)" or
    not "癌症分期分數或結果為M>=1" or
    ("3個月內有檢查報告" and not "3個月內影像報告") or
    (not "3個月內有檢查報告" and "3個月內影像報告") or
    not "1條件2-2=之前已經接受過轉移性癌症治療，或在輔助療法治療期間或完成治療後6個月內癌症復發" or
    not "1條件2-3=合併有主要臟器(不包含骨及軟組織)轉移"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "HER2過度表現(IHC3+或FISH+)"
           then '▲ 條件1(HER2)：未提供HER2檢測報告(IHC或FISH)\n' else '') +
         (if not "癌症分期分數或結果為M>=1"
           then '▲ 條件1(分期)：未提供癌症分期資料(M分期)\n' else '') +
         (if "3個月內有檢查報告" and not "3個月內影像報告"
           then '▲ 條件1(報告)：已提供分子檢查報告但缺少3個月內影像報告，兩者須同時提供\n' else '') +
         (if not "3個月內有檢查報告" and "3個月內影像報告"
           then '▲ 條件1(報告)：已提供影像報告但缺少3個月內分子檢查報告，兩者須同時提供\n' else '') +
         (if not "1條件2-2=之前已經接受過轉移性癌症治療，或在輔助療法治療期間或完成治療後6個月內癌症復發"
           then '▲ 條件2-2：未於病摘中敘明轉移性癌症治療史或癌症復發狀況\n' else '') +
         (if not "1條件2-3=合併有主要臟器(不包含骨及軟組織)轉移"
           then '▲ 條件2-3：未於病摘中敘明主要臟器轉移情形，或癌症分期未達M≥1\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (
    not "規則1-1=每12週須再次申請並檢附療效評估資料" or
    not "規則1-2=疾病有惡化情形須停止使用"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if not "規則1-1=每12週須再次申請並檢附療效評估資料"
           then '▲ 續用條件1：未於12週內再次申請，或未檢附療效評估資料，或申請療程超過12週(84天)\n' else '') +
         (if not "規則1-2=疾病有惡化情形須停止使用"
           then '▲ 續用條件2：未提供前次治療後之影像學報告\n' else '') +
         '\n'
    else '')


//============================================
// 審核結果
//============================================

define "乳癌TrastuzumabDeruxtecanHER2過度表現申請結果_布林":
  case
    when Reusable."初次申請" then (
      "主要規定一" and
      "主要規定三"
    )
    when Reusable."續用申請" then
      "主要規定二"
    else false
  end

define "乳癌TrastuzumabDeruxtecanHER2過度表現申請之CQL檢核結果":
  if (
    Reusable."初次申請" and
    "主要規定一" and
    "主要規定三"
  )
  then '✓通過：初次使用－轉移性乳癌(HER2+)Trastuzumab Deruxtecan用藥申請'

  else if (
    Reusable."續用申請" and
    "主要規定二"
  )
  then '✓通過：續用－轉移性乳癌(HER2+)Trastuzumab Deruxtecan用藥申請'

  else if Reusable."初次申請"
  then '✖不通過：初次使用－轉移性乳癌(HER2+)Trastuzumab Deruxtecan用藥申請'

  else if Reusable."續用申請"
  then '✖不通過：續用－轉移性乳癌(HER2+)Trastuzumab Deruxtecan用藥申請'

  else '✖不通過：無法判定申請類型－轉移性乳癌(HER2+)Trastuzumab Deruxtecan用藥申請'


//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 早期乳癌（二線治療）之Trastuzumab Deruxtecan申請審核報告 ===\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 代碼或條件不符】\n' +
  (if "不符合項目_代碼或條件不符"() = '' then '無\n' else "不符合項目_代碼或條件不符"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【申請結果】\n' +
  "乳癌TrastuzumabDeruxtecanHER2過度表現申請之CQL檢核結果" +
  '\n===============================================\n'
