//轉移性乳癌_Pertuzumab與Trastuzumab_皮下(SC)給付規定

library BCPertuzumabTrastuzumabSCRule2 version '1.0.0'

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



//1條件1:與docetaxel併用
define "1條件1=與docetaxel併用":
  Reusable."HasConcurrentMedicationOrder"(CodeConcept."L01FY01", CodeConcept."L01CD02")
  and Reusable."醫令類別為1"


//1條件2
//1條件2-1:未曾以抗HER2療法治療（完全未曾使用過）
define "1條件2-1=未曾以抗HER2療法治療":
  not exists (
    [MedicationRequest] MR
    where (MR.intent = 'plan' or MR.intent = 'order')
    and exists (
      MR.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
      and Cdg.code in CodeConcept."PertuzumabTrastuzumabSC之抗HER2治療"
    )
  )


//1條件2-2:未曾以化學療法治療（完全未曾使用過）
define "1條件2-2=未曾以化學療法治療":
  not exists (
    [MedicationRequest] MR
    where (MR.intent = 'plan' or MR.intent = 'order')
    and exists (
      MR.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
      and Cdg.code in CodeConcept."併用化學治療法"
    )
  )

define "1條件2=未曾以抗HER2或化學療法治療":
"1條件2-1=未曾以抗HER2療法治療" or "1條件2-2=未曾以化學療法治療"


//1條件3:HER2過度表現(IHC3+或FISH+)轉移性乳癌病人

//1條件3-1
define "1條件3-1=3個月內影像報告":
Reusable."HasRecentImageReport"("本次申請起始日期", 90)


//1條件3-2
define "1條件3-2=癌症分期分數或結果為M>=1":
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

//1條件3-3(檢查報告)
define "1條件3-3=3個月內有檢查報告":
Reusable."HasRecentMolecularReport"("本次申請起始日期", 90)


//1條件3-4
define "1條件3-4=檢驗檢查-具HER2過度表現":
  Reusable."HasHER2OverexpressionTest"

define "1條件3-4=基因檢測-具HER2過度表現":
  Reusable."HasHER2OverexpressionGene"

define "1條件3-4=具HER2過度表現":
  "1條件3-4=檢驗檢查-具HER2過度表現"
  or "1條件3-4=基因檢測-具HER2過度表現"


define "1條件3=HER2過度表現(IHC3+或FISH+)轉移性乳癌病人":
  "ICD代碼檢核_布林值" 
  and "醫令類別為1_布林值" 
  and "1條件3-2=癌症分期分數或結果為M>=1"
  and "1條件3-4=具HER2過度表現"
  and ("1條件3-1=3個月內影像報告" or "1條件3-3=3個月內有檢查報告")



//規則1
define "1規則1":
"1條件1=與docetaxel併用" and "1條件2=未曾以抗HER2或化學療法治療" and "1條件3=HER2過度表現(IHC3+或FISH+)轉移性乳癌病人"

/*規則2*/

//2條件1：不存在 L01FD02+L01FD01 併用紀錄 → TRUE（可申請L01FY01）；存在 → FALSE（不可申請）
define "2條件1=於早期乳癌已使用過本藥品或pertuzumab與trastuzumab併用者，不得再次申請本藥品":
  not exists (
    [MedicationRequest] MR1
    where MR1.intent = 'order'
    and exists (
      MR1.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
      and Cdg.code in CodeConcept.L01FD02
    )
    and exists (
      [MedicationRequest] MR2
      where MR2.intent = 'order'
      and exists (
        MR2.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.L01FD01
      )
      and Reusable."HasValidTiming"(MR1)
      and MR1.dosageInstruction[0].timing.repeat.bounds is Period
      and (start of (MR1.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
      and (end of (MR1.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
      and Reusable."HasValidTiming"(MR2)
      and MR2.dosageInstruction[0].timing.repeat.bounds is Period
      and (start of (MR2.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
      and (end of (MR2.dosageInstruction[0].timing.repeat.bounds as Period)) is not null
      and (start of (MR1.dosageInstruction[0].timing.repeat.bounds as Period))
          <= (end of (MR2.dosageInstruction[0].timing.repeat.bounds as Period))
      and (end of (MR1.dosageInstruction[0].timing.repeat.bounds as Period))
          >= (start of (MR2.dosageInstruction[0].timing.repeat.bounds as Period))
    )
  )


//2條件2:病摘敘明早期乳癌治療結束時間與首次疾病復發轉移時間超過12個月以上
define "2條件2=病摘敘明早期乳癌治療結束至首次疾病復發轉移時間超過12個月以上":
  exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where Matches(T.value, '(?i).*(早期乳癌治療結束.*首次.*復發.*超過12個月|治療結束.*復發轉移.*12個月以上|早期.*結束.*轉移.*超過12個月|首次復發轉移距.*結束.*12個月).*')
          )
      )
  )


//規則2
define "1規則2":
  "2條件1=於早期乳癌已使用過本藥品或pertuzumab與trastuzumab併用者，不得再次申請本藥品"
    and "2條件2=病摘敘明早期乳癌治療結束至首次疾病復發轉移時間超過12個月以上"



//主要規定一
define "主要規定一":
"1規則1" or "1規則2"


//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

//條件1:每18週須檢附療效評估資料再次申請，若疾病有惡化情形即不應再行申請
// 本次申請紀錄（以最新一筆申請作為本次申請）
define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.L01FY01)

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

// 前次申請紀錄（本次申請之前最近一次的申請）
define "前次申請紀錄":
  Reusable."LatestMedicationPlanBefore"(CodeConcept.L01FY01, "本次申請起始日期")

// 檢查18週間隔的邏輯
define "規則1-1=每18週須再次申請並檢附療效評估資料":
  Reusable."醫令類別為1" 
  and Reusable."續用註記為2"
  and "前次申請紀錄" is not null
  and "本次申請紀錄" is not null
  and (
    // 計算前次申請結束日期到本次申請開始日期的天數差異
    difference in days between
      FHIRHelpers.ToDateTime(("前次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).end)
      and FHIRHelpers.ToDateTime(("本次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).start)
  ) <= 126  // 18週 = 126天


//條件2:疾病有惡化情形須停止使用

// 取得前次治療紀錄（最近一次已完成的治療）
define "前次治療紀錄":
  Reusable."LatestCompletedMedicationOrderBefore"(CodeConcept.L01FY01, "本次申請起始日期")

// 前次用藥開始日期
define "前次用藥開始日期":
  Reusable."GetStartTime"("前次治療紀錄")

// 規則1-2: 疾病有惡化情形須停止使用(續用須檢附前次治療後影像學報告)
define "規則1-2=疾病有惡化情形須停止使用":
  Reusable."HasImageReportBetweenPreviousTreatmentAndCurrentApply"(CodeConcept.L01FY01)

// 主要規定二
define "主要規定二":
Reusable."續用註記為2"
and "規則1-1=每18週須再次申請並檢附療效評估資料"
and "規則1-2=疾病有惡化情形須停止使用"


//============================================
// 主要規定三：藥品使用規則
//============================================
//三種用藥選擇合併療程計算，上限為18個療程
// 每周療程: count(MR where count=1) ≤ 18 且 sum(useEdate-useSdate) ≤ 126天
define "三種用藥合併每周療程上限18個療程":
  Count(
    [MedicationRequest] MR
      where MR.intent = 'plan'
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and (Cdg.code in CodeConcept.L01FY01
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
define "三種用藥合併每三周療程上限18個療程":
  // 計算三種用藥合併後的代表療程數
  Count(
    [MedicationRequest] MR
      where MR.intent = 'plan'
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and (Cdg.code in CodeConcept.L01FY01
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

define "主要規定三":
  "三種用藥合併每周療程上限18個療程"
  or "三種用藥合併每三周療程上限18個療程"


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and "主要規定一"
    then '<主要規定一：初次使用條件>\n' +
         (if "ICD代碼檢核_布林值"
           then '● ICD代碼為C50\n' else '') +
         (if "1條件1=與docetaxel併用"
           then '● 規則1-條件1：本藥品與docetaxel併用\n' else '') +
         (if "1條件2-1=未曾以抗HER2療法治療"
           then '● 規則1-條件2-1：未曾以抗HER2療法治療\n' else '') +
         (if "1條件2-2=未曾以化學療法治療"
           then '● 規則1-條件2-2：未曾以化學療法治療\n' else '') +
         (if "1條件3-1=3個月內影像報告"
           then '● 規則1-條件3-1：3個月內影像報告\n' else '') +
         (if "1條件3-2=癌症分期分數或結果為M>=1"
           then '● 規則1-條件3-2：癌症分期M≥1（轉移性）\n' else '') +
         (if "1條件3-3=3個月內有檢查報告"
           then '● 規則1-條件3-3：3個月內有檢查報告\n' else '') +
         (if "1條件3-4=具HER2過度表現"
           then '● 規則1-條件3-4：具HER2過度表現（IHC3+或FISH+）\n' else '') +
         (if "2條件1=於早期乳癌已使用過本藥品或pertuzumab與trastuzumab併用者，不得再次申請本藥品"
           then '● 規則2-條件1：未曾於早期乳癌使用pertuzumab與trastuzumab併用\n' else '') +
         (if "2條件2=病摘敘明早期乳癌治療結束至首次疾病復發轉移時間超過12個月以上"
           then '● 規則2-條件2：病摘敘明早期乳癌治療結束至首次疾病復發轉移超過12個月\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件
  (if Reusable."續用申請" and "主要規定二"
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if "規則1-1=每18週須再次申請並檢附療效評估資料"
           then '● 續用規則1-1：於18週內再次申請並檢附療效評估資料\n' else '') +
         (if "規則1-2=疾病有惡化情形須停止使用"
           then '● 續用規則1-2：已檢附前次治療後影像學報告，確認無惡化\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則
  (if "主要規定三"
    then '<主要規定三：藥品使用規則>\n' +
         (if "三種用藥合併每周療程上限18個療程"
           then '● 規則3：每周療程合計≤18個療程且總日數≤126天\n' else '') +
         (if "三種用藥合併每三周療程上限18個療程"
           then '● 規則3：每三周療程合計≤18個療程且總日數≤378天\n' else '') +
         '\n'
    else '')


//============================================
// 列出「不符合」項目判斷式 - 代碼或條件不符
//============================================

define function "不符合項目_代碼或條件不符"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if Reusable."初次申請" and (
    not "ICD代碼檢核_布林值" or
    not "1條件3-2=癌症分期分數或結果為M>=1" or
    not "1條件3-4=具HER2過度表現"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "ICD代碼檢核_布林值"
           then '▲ 規則1-0：主要疾病之ICD代碼未使用C50\n' else '') +
         (if not "1條件3-2=癌症分期分數或結果為M>=1"
           then '▲ 規則1-條件3-2：癌症分期不符合（需M≥1，具遠處轉移）\n' else '') +
         (if not "1條件3-4=具HER2過度表現"
           then '▲ 規則1-條件3-4：HER2未過度表現或未提供（需IHC3+或FISH+）\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 代碼條件不符
  (if not "主要規定三"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則3：三種用藥（L01FY01/L01FD01andL01FD02）合計療程超過18個療程\n' +
         '\n'
    else '')


//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
    not "1條件1=與docetaxel併用" or
    not ("1條件3-1=3個月內影像報告" or "1條件3-3=3個月內有檢查報告") or
    not ("1條件2-1=未曾以抗HER2療法治療" or "1條件2-2=未曾以化學療法治療") or
    not "2條件2=病摘敘明早期乳癌治療結束至首次疾病復發轉移時間超過12個月以上"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "1條件1=與docetaxel併用"
           then '▲ 規則1-條件1：未申請本藥品與docetaxel併用\n' else '') +
         (if not ("1條件3-1=3個月內影像報告" or "1條件3-3=3個月內有檢查報告")
           then '▲ 規則1-條件3：未提供3個月內影像報告或檢查報告\n' else '') +
         (if not "1條件2-1=未曾以抗HER2療法治療" and not "1條件2-2=未曾以化學療法治療"
           then '▲ 規則1-條件2：曾以抗HER2療法且曾以化學療法治療\n' else '') +
         (if not "2條件2=病摘敘明早期乳癌治療結束至首次疾病復發轉移時間超過12個月以上"
           then '▲ 規則2-條件2：病摘未敘明早期乳癌治療結束至首次疾病復發轉移時間超過12個月\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (
    not "規則1-1=每18週須再次申請並檢附療效評估資料" or
    not "規則1-2=疾病有惡化情形須停止使用"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if not "規則1-1=每18週須再次申請並檢附療效評估資料"
           then '▲ 續用規則1-1：未於18週內再次申請或未檢附療效評估資料\n' else '') +
         (if not "規則1-2=疾病有惡化情形須停止使用"
           then '▲ 續用規則1-2：未提供前次治療後影像學報告\n' else '') +
         '\n'
    else '')


//============================================
// 審核結果
//============================================

define "乳癌PertuzumabTrastuzumabSC轉移性申請結果_布林":
  case
    when Reusable."初次申請" then (
      "主要規定一" and
      "主要規定三"
    )
    when Reusable."續用申請" then (
      "主要規定二" and
      "主要規定三"
    )
    else false
  end

define "乳癌PertuzumabTrastuzumabSC轉移性申請之CQL檢核結果":
  if (
    Reusable."初次申請" and
    "主要規定一" and
    "主要規定三"
  )
  then '✓通過：初次使用－轉移性乳癌 PertuzumabTrastuzumabSC 用藥申請'

  else if (
    Reusable."續用申請" and
    "主要規定二" and
    "主要規定三"
  )
  then '✓通過：續用－轉移性乳癌 PertuzumabTrastuzumabSC 用藥申請'

  else if Reusable."初次申請"
  then '✖不通過：初次使用－轉移性乳癌 PertuzumabTrastuzumabSC 用藥申請'

  else if Reusable."續用申請"
  then '✖不通過：續用－轉移性乳癌 PertuzumabTrastuzumabSC 用藥申請'

  else '✖不通過：無法判定申請類型－轉移性乳癌 PertuzumabTrastuzumabSC 用藥申請'


//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 轉移性乳癌之PertuzumabTrastuzumabSC 申請審核報告 ===\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 代碼或條件不符】\n' +
  (if "不符合項目_代碼或條件不符"() = '' then '無\n' else "不符合項目_代碼或條件不符"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【申請結果】\n' +
  "乳癌PertuzumabTrastuzumabSC轉移性申請之CQL檢核結果" +
  '\n===============================================\n'
