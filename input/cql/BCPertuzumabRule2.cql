//轉移性乳癌_Pertuzumab給付規定

library BCPertuzumabRule2 version '1.0.0'

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

define "Pertuzumab申請":
  exists (        
    [MedicationRequest] MRPlan
    where MRPlan.intent = 'plan'
      and exists (
        MRPlan.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
          and Cdg.code in CodeConcept.L01FD02
      )
  )

//條件1:轉移性乳癌
//條件1-1
define "條件1-1=3個月內影像報告":
Reusable."HasRecentImageReport"("本次申請起始日期", 90)


//條件1-2
define "條件1-2=癌症分期分數或結果為M≠0":
  Reusable."癌症分期分數或結果為M≠0"

//條件1-3(檢查報告)
define "條件1-3=3個月內有檢查報告":
Reusable."HasRecentMolecularReport"("本次申請起始日期", 90)


define "條件1=轉移性乳癌":
  "ICD代碼檢核_布林值" 
  and "醫令類別為1_布林值" 
  and "Pertuzumab申請"
  and "條件1-2=癌症分期分數或結果為M≠0"
  and ("條件1-1=3個月內影像報告" or "條件1-3=3個月內有檢查報告")


//條件2:HER2過度表現(IHC3+或FISH+)
define "條件2=檢驗檢查-具HER2過度表現":
  Reusable."HasHER2OverexpressionTest"

define "條件2=基因檢測-具HER2過度表現":
  Reusable."HasHER2OverexpressionGene"

define "條件2=具HER2過度表現":
  "條件2=檢驗檢查-具HER2過度表現"
  or "條件2=基因檢測-具HER2過度表現"


//條件3-1:轉移後未曾以抗HER2治療
define "本次Pertuzumab申請起始日":
  FHIRHelpers.ToDateTime(
    (First(
      [MedicationRequest] MR
        where MR.intent = 'plan'
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and Cdg.code in CodeConcept.L01FD02
        )
        and MR.dosageInstruction[0].timing.repeat.bounds is Period
      sort by FHIRHelpers.ToDateTime((dosageInstruction[0].timing.repeat.bounds as Period).start)
    ).dosageInstruction[0].timing.repeat.bounds as Period).start
  )

define "轉移確認日期":
  Last(
    [Observation] O
      where exists (
        O.code.coding Cdg
          where Cdg.code = '399390009'
            and Cdg in CodeConcept.SNOMED
      )
      and O.value is FHIR.string
      and Matches((O.value as FHIR.string).value, '.*M[1-9].*')
    sort by FHIRHelpers.ToDateTime(effective as FHIR.dateTime)
  ).effective

define "條件3-1=轉移後未曾以抗HER2治療":
  "轉移確認日期" is not null
  and not exists (
    [MedicationRequest] MR
      where MR.intent = 'order'
      and exists (
        MR.medication.coding Cdg
          where Cdg in CodeConcept.NHIMedication
            and Cdg.code in CodeConcept."Pertuzumab之抗HER2治療"
      )
      and MR.dosageInstruction[0].timing.repeat.bounds is Period
      // 轉移確認日期之後、本次申請起始日之前
      and FHIRHelpers.ToDateTime(
          (MR.dosageInstruction[0].timing.repeat.bounds as Period).start
        ) >= FHIRHelpers.ToDateTime("轉移確認日期" as FHIR.dateTime)
      and FHIRHelpers.ToDateTime(
          (MR.dosageInstruction[0].timing.repeat.bounds as Period).start
        ) < "本次Pertuzumab申請起始日"
  )

//條件3-2:轉移後未曾以化學療法治療
define "條件3-2=轉移後未曾以化學療法治療":
  "轉移確認日期" is not null
  and not exists (
    [MedicationRequest] MR
      where MR.intent = 'order'
      and exists (
        MR.medication.coding Cdg
          where Cdg in CodeConcept.NHIMedication
            and Cdg.code in CodeConcept."Pertuzumab之化學療法治療"
      )
      and MR.dosageInstruction[0].timing.repeat.bounds is Period
      // 轉移確認日期之後、本次申請起始日之前
      and FHIRHelpers.ToDateTime(
          (MR.dosageInstruction[0].timing.repeat.bounds as Period).start
        ) >= FHIRHelpers.ToDateTime("轉移確認日期" as FHIR.dateTime)
      and FHIRHelpers.ToDateTime(
          (MR.dosageInstruction[0].timing.repeat.bounds as Period).start
        ) < "本次Pertuzumab申請起始日"
  )


//條件4:與trastuzumab併用
define "條件4=與trastuzumab併用":
  Reusable."HasConcurrentMedicationOrder"(CodeConcept."L01FD02", CodeConcept."L01FD01")
  and Reusable."醫令類別為1"

//條件5:與docetaxel併用
define "條件5=與docetaxel併用":
  Reusable."HasConcurrentMedicationOrder"(CodeConcept."L01FD02", CodeConcept."L01CD02")
  and Reusable."醫令類別為1"

//主要規定一
define "主要規定一":
"條件1=轉移性乳癌" 
and "條件2=具HER2過度表現"
and "條件3-1=轉移後未曾以抗HER2治療"
and "條件3-2=轉移後未曾以化學療法治療"
and "條件4=與trastuzumab併用"
and "條件5=與docetaxel併用"


//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

//條件1:每18週須檢附療效評估資料再次申請，若疾病有惡化情形即不應再行申請
// 本次申請紀錄（以最新一筆申請作為本次申請）
define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.L01FD02)

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

// 前次申請紀錄（本次申請之前最近一次的申請）
define "前次申請紀錄":
  Reusable."LatestMedicationPlanBefore"(CodeConcept.L01FD02, "本次申請起始日期")

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
  Reusable."LatestCompletedMedicationOrderBefore"(CodeConcept.L01FD02, "本次申請起始日期")

// 前次用藥開始日期
define "前次用藥開始日期":
  Reusable."GetStartTime"("前次治療紀錄")

// 規則1-2: 疾病有惡化情形須停止使用(續用須檢附前次治療後影像學報告)
define "規則1-2=疾病有惡化情形須停止使用":
  Reusable."HasImageReportBetweenPreviousTreatmentAndCurrentApply"(CodeConcept.L01FD02)

// 主要規定二
define "主要規定二":
Reusable."續用註記為2"
and "規則1-1=每18週須再次申請並檢附療效評估資料"
and "規則1-2=疾病有惡化情形須停止使用"


//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
//規則1:轉移性乳癌總療程I+II 18個月為上限 (Ｉ：pertuzumab 與trastuzumab 併用；Ⅱ：pertuzumab 與trastuzumab 皮下注射複方製劑(如Phesgo))
// 每3週為一個療程，最多18個療程 → 18 × 21天 = 378天
// 加總所有處方的實際起訖天數（不含空窗期），合計不得超過378天
define "規則1=得繼續使用至18個療程為上限":
  Sum(
    [MedicationRequest] MR
      where MR.intent = 'plan'
        and exists (
          MR.medication.coding Cdg
            where Cdg in CodeConcept.NHIMedication
              and (Cdg.code in CodeConcept.L01FY01
                or Cdg.code in CodeConcept.L01FD01
                or Cdg.code in CodeConcept.L01FD02)
        )
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
  ) <= 378

/*規則2*/
//條件1:於早期乳癌已使用pertuzumab 與trastuzumab 併用或使用pertuzumab 與trastuzumab 皮下注射複方製劑(如Phesgo)者
//於病歷上註記轉移日期前
//條件2:早期乳癌治療結束至首次疾病復發轉移時間為12個月以內
define "條件1/條件2=於早期乳癌已使用pertuzumab 與trastuzumab 併用或使用pertuzumab 與trastuzumab 皮下注射複方製劑(如Phesgo)者":
  "轉移確認日期" is not null
  and exists (
    [MedicationRequest] MR
      where MR.intent = 'order'
      and exists (
        MR.medication.coding Cdg
          where Cdg in CodeConcept.NHIMedication
            and (Cdg.code in CodeConcept.L01FY01
              or Cdg.code in CodeConcept.L01FD01
              or Cdg.code in CodeConcept.L01FD02)
      )
      and MR.dosageInstruction[0].timing.repeat.bounds is Period
      // 治療起始日須早於病歷上註記之轉移確認日期（早期乳癌治療在轉移前）
      and FHIRHelpers.ToDateTime(
          (MR.dosageInstruction[0].timing.repeat.bounds as Period).start
        ) < FHIRHelpers.ToDateTime("轉移確認日期" as FHIR.dateTime)
      // 早期乳癌治療結束至首次轉移時間須在12個月以內（結束日 >= 轉移確認日期 - 12個月）
      and FHIRHelpers.ToDateTime(
          (MR.dosageInstruction[0].timing.repeat.bounds as Period).end
        ) >= (FHIRHelpers.ToDateTime("轉移確認日期" as FHIR.dateTime) - 12 months)
  )


//條件3:不得再次申請pertuzumab 與trastuzumab 併用 同 條件4=與trastuzumab併用
define "規則2":
  if "條件1/條件2=於早期乳癌已使用pertuzumab 與trastuzumab 併用或使用pertuzumab 與trastuzumab 皮下注射複方製劑(如Phesgo)者"
    then not "條件4=與trastuzumab併用"
  else true

// 主要規定三
define "主要規定三":
"規則1=得繼續使用至18個療程為上限" and "規則2"


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and (
    "ICD代碼檢核_布林值" or
    "醫令類別為1_布林值" or
    "Pertuzumab申請" or
    "條件1-1=3個月內影像報告" or
    "條件1-2=癌症分期分數或結果為M≠0" or
    "條件1-3=3個月內有檢查報告" or
    "條件2=具HER2過度表現" or
    "條件3-1=轉移後未曾以抗HER2治療" or
    "條件3-2=轉移後未曾以化學療法治療" or
    "條件4=與trastuzumab併用" or
    "條件5=與docetaxel併用"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "ICD代碼檢核_布林值"
           then '● ICD代碼檢核：主要疾病之ICD代碼使用C50\n' else '') +
         (if "醫令類別為1_布林值"
           then '● 醫令類別檢核：醫令類別為1(癌症治療)\n' else '') +
         (if "Pertuzumab申請"
           then '● Pertuzumab申請\n' else '') +
         (if "條件1-1=3個月內影像報告"
           then '● 條件1-1：3個月內影像報告\n' else '') +
         (if "條件1-2=癌症分期分數或結果為M≠0"
           then '● 條件1-2：癌症分期為M≠0（轉移性）\n' else '') +
         (if "條件1-3=3個月內有檢查報告"
           then '● 條件1-3：3個月內有檢查報告\n' else '') +
         (if "條件2=具HER2過度表現"
           then '● 條件2：具HER2過度表現（IHC3+或FISH+）\n' else '') +
         (if "條件3-1=轉移後未曾以抗HER2治療"
           then '● 條件3-1：轉移後未曾以抗HER2治療\n' else '') +
         (if "條件3-2=轉移後未曾以化學療法治療"
           then '● 條件3-2：轉移後未曾以化學療法治療\n' else '') +
         (if "條件4=與trastuzumab併用"
           then '● 條件4：與trastuzumab併用\n' else '') +
         (if "條件5=與docetaxel併用"
           then '● 條件5：與docetaxel併用\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件
  (if Reusable."續用申請" and (
    "規則1-1=每18週須再次申請並檢附療效評估資料" or
    "規則1-2=疾病有惡化情形須停止使用"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if "規則1-1=每18週須再次申請並檢附療效評估資料"
           then '● 規則1-1：符合18週（126天）內再次申請\n' else '') +
         (if "規則1-2=疾病有惡化情形須停止使用"
           then '● 規則1-2：已提供前次治療後影像學報告\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則
  (if "規則1=得繼續使用至18個療程為上限" or "規則2"
    then '<主要規定三：藥品使用規則>\n' +
         (if "規則1=得繼續使用至18個療程為上限"
           then '● 規則1：總療程天數未超過378天（18個療程×21天）\n' else '') +
         (if "規則2"
           then '● 規則2：符合pertuzumab與trastuzumab併用限制\n' else '') +
         '\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 代碼或條件不符
//============================================

define function "不符合項目_代碼或條件不符"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if Reusable."初次申請" and (
    not "ICD代碼檢核_布林值" or
    not "醫令類別為1_布林值" or
    not "條件2=具HER2過度表現" or
    not "條件3-1=轉移後未曾以抗HER2治療" or
    not "條件3-2=轉移後未曾以化學療法治療" or
    not "條件4=與trastuzumab併用" or
    not "條件5=與docetaxel併用"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "ICD代碼檢核_布林值"
           then '▲ ICD代碼檢核：主要疾病之ICD代碼未使用C50\n' else '') +
         (if not "醫令類別為1_布林值"
           then '▲ 醫令類別檢核：醫令類別非1\n' else '') +
         (if not "條件2=具HER2過度表現"
           then '▲ 條件2：HER2未達過度表現標準（需IHC3+或FISH+）\n' else '') +
         (if not "條件3-1=轉移後未曾以抗HER2治療"
           then '▲ 條件3-1：轉移後曾接受抗HER2治療，不符合初次給付資格\n' else '') +
         (if not "條件3-2=轉移後未曾以化學療法治療"
           then '▲ 條件3-2：轉移後曾接受化學療法治療，不符合初次給付資格\n' else '') +
         (if not "條件4=與trastuzumab併用"
           then '▲ 條件4：未與trastuzumab併用\n' else '') +
         (if not "條件5=與docetaxel併用"
           then '▲ 條件5：未與docetaxel併用\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 代碼條件不符
  (if not "規則1=得繼續使用至18個療程為上限" or not "規則2"
    then '<主要規定三：藥品使用規則>\n' +
         (if not "規則1=得繼續使用至18個療程為上限"
           then '▲ 規則1：總療程天數超過378天（超過18個療程×21天上限）\n' else '') +
         (if not "規則2"
           then '▲ 規則2：早期乳癌已使用pertuzumab與trastuzumab且轉移時間在12個月內，不得再次申請併用\n' else '') +
         '\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
    not "Pertuzumab申請" or
    not ("條件1-1=3個月內影像報告" or "條件1-3=3個月內有檢查報告") or
    not "條件1-2=癌症分期分數或結果為M≠0"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "Pertuzumab申請"
           then '▲ 未提供Pertuzumab申請資料\n' else '') +
         (if not "條件1-1=3個月內影像報告" and not "條件1-3=3個月內有檢查報告"
           then '▲ 條件1-1/1-3：未提供3個月內影像報告或檢查報告\n' else '') +
         (if not "條件1-2=癌症分期分數或結果為M≠0"
           then '▲ 條件1-2：未提供癌症分期資料或非轉移性（M=0）\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (
    not "規則1-1=每18週須再次申請並檢附療效評估資料" or
    not "規則1-2=疾病有惡化情形須停止使用"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if not "規則1-1=每18週須再次申請並檢附療效評估資料"
           then '▲ 規則1-1：申請間隔超過18週（126天）或缺少前次申請紀錄\n' else '') +
         (if not "規則1-2=疾病有惡化情形須停止使用"
           then '▲ 規則1-2：未提供前次治療後之影像學報告\n' else '') +
         '\n'
    else '')

//============================================
// 審核結果
//============================================

define "乳癌Pertuzumab轉移性申請結果_布林":
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

define "乳癌Pertuzumab轉移性申請之CQL檢核結果":
  if (
    Reusable."初次申請" and
    "主要規定一" and
    "主要規定三"
  )
  then '✓通過：初次使用－轉移性乳癌 Pertuzumab 用藥申請'

  else if (
    Reusable."續用申請" and
    "主要規定二" and
    "主要規定三"
  )
  then '✓通過：續用－轉移性乳癌 Pertuzumab 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－轉移性乳癌 Pertuzumab 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－轉移性乳癌 Pertuzumab 用藥申請'
  else '✖不通過：無法判定申請類型－轉移性乳癌 Pertuzumab 用藥申請'

//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 轉移性乳癌 Pertuzumab 申請審核報告 ===\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 代碼或條件不符】\n' +
  (if "不符合項目_代碼或條件不符"() = '' then '無\n' else "不符合項目_代碼或條件不符"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【申請結果】\n' +
  "乳癌Pertuzumab轉移性申請之CQL檢核結果" +
  '\n===============================================\n'
