//轉移性乳癌_Trastuzumab Deruxtecan給付規定
library BCTrastuzumabDeruxtecanRule2 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include BCCodeConcept version '1.0.0' called CodeConcept

include BCReusable version '1.0.0' called Reusable

context Patient


//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/

//1條件1:單獨使用於ER、PR皆陰性
define "檢驗檢查-ER陰性":
  Reusable."HasMarkerNegativeTest"(CodeConcept.MolecularER)

define "基因檢測-ER陰性":
  Reusable."HasMarkerNegativeGene"(CodeConcept.MolecularER)

define "ER陰性":
  "檢驗檢查-ER陰性" or "基因檢測-ER陰性"

//條件5-2
define "檢驗檢查-PR陰性":
  Reusable."HasMarkerNegativeTest"(CodeConcept.MolecularPR)

define "基因檢測-PR陰性":
  Reusable."HasMarkerNegativeGene"(CodeConcept.MolecularPR)

define "PR陰性":
  "檢驗檢查-PR陰性" or "基因檢測-PR陰性"

define "基因檢測報告":
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
              and Cdg.code in {'102116-1', '104295-1'}
        )
    )
  )

define "1條件1=單獨使用於ER、PR皆陰性":
"ER陰性" 
and "PR陰性"
and "基因檢測報告"

//1條件2: HER2弱陽性(IHC 1+或IHC 2+/ISH-)表現

define "檢驗檢查-HER2弱陽性(IHC 1+或IHC 2+/ISH-)表現":
  Reusable."HasHER2LowExpressionTest"

define "基因檢測-HER2弱陽性(IHC 1+或IHC 2+/ISH-)表現":
  Reusable."HasHER2LowExpressionGene"

define "HER2弱陽性(IHC 1+或IHC 2+/ISH-)表現":
  "檢驗檢查-HER2弱陽性(IHC 1+或IHC 2+/ISH-)表現"
  or "基因檢測-HER2弱陽性(IHC 1+或IHC 2+/ISH-)表現"

  define "HER2弱陽性-基因檢測報告":
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
              and Cdg.code in CodeConcept."HER2弱陽性"
        )
    )
  )


define "1條件2=HER2弱陽性表現":
"HER2弱陽性(IHC 1+或IHC 2+/ISH-)表現" 
and "HER2弱陽性-基因檢測報告"


//1條件3:無法切除的局部晚期或轉移性乳癌病人
define "ICD代碼檢核_布林值": Reusable."ICD-10使用C50"

define "醫令類別為1_布林值": Reusable."醫令類別為1"

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


define "病摘判斷無法切除":
    exists (
        [Claim] C
        where exists (
            C.diagnosis D
            where exists (
                D.type.text T
                where Matches(T.value, '(?i).*(無法切除).*')
            )
        )
    )

define "1條件3=無法切除的局部晚期或轉移性乳癌病人":
Reusable."ICD-10使用C50"
and Reusable."醫令類別為1"
and "病摘判斷無法切除"
and "癌症分期分數或結果為M>=1"
and (
  (not "3個月內影像報告" and not "3個月內有檢查報告")
  or ("3個月內影像報告" and "3個月內有檢查報告")
)

define "規則1=單獨使用於ER、PR皆陰性且具 HER2弱陽性表現之無法切除的局部晚期或轉移性乳癌病人":
"1條件1=單獨使用於ER、PR皆陰性"
and "1條件2=HER2弱陽性表現"
and "1條件3=無法切除的局部晚期或轉移性乳癌病人"


/*規則2*/
//符合下列各項條件：
//(1)病人身體狀況良好（ECOG<=1）。
//(2)須接受過至少一種化學療法治療。
//(3)須經事前審查核准後使用，每次申請之療程以12週為限，初次申請時需檢附ER、PR皆為陰性且HER2弱陽性(IHC1+或IHC2+/ISH-)之檢測報告。

//2條件1:病人身體狀況良好（ECOG<=1）
define "2條件1=病人身體狀況良好(ECOG≦1)":
  exists (
    [Observation] OBs
    where exists (
      OBs.category C
      where exists (
        C.coding Cdg
        where Cdg in CodeConcept.NHIPASSupportingInfoType
        and Cdg.code = 'patientAssessment'
      )
    )
    and exists (
      OBs.code.coding Cdg
      where Cdg in CodeConcept.LOINC
      and Cdg.code = '89247-1'
    )
    and OBs.value is FHIR.integer
    and (OBs.value as FHIR.integer) <= 1
  )

//2條件2:須接受過至少一種化學療法治療
define "2條件2=與化學療法併用":
  Reusable."HasConcurrentMedicationOrder"(CodeConcept.L01FD04, CodeConcept."化學療法")
  and Reusable."醫令類別為1"


//2條件3:初次申請時需檢附ER、PR皆為陰性且HER2弱陽性之檢測報告 上述以包含

define "規則2=符合下列各項條件":
"2條件1=病人身體狀況良好(ECOG≦1)"
and "2條件2=與化學療法併用"

//主要規定一
define "主要規定一":
"規則1=單獨使用於ER、PR皆陰性且具 HER2弱陽性表現之無法切除的局部晚期或轉移性乳癌病人"
and "規則2=符合下列各項條件"


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

//取得前次治療紀錄（最近一次已完成的治療）
define "前次治療紀錄":
  Reusable."LatestCompletedMedicationOrderBefore"(CodeConcept.L01FD04, "本次申請起始日期")

// 前次用藥開始日期
define "前次用藥開始日期":
  Reusable."GetStartTime"("前次治療紀錄")

// 規則1-2: 疾病有惡化情形須停止使用(續用須檢附前次治療後影像學報告)
define "規則1-2=疾病有惡化情形須停止使用":
  exists (
    [DiagnosticReport] O
    where exists (
      O.code.coding Cdg
      where (
        Cdg in CodeConcept.ICD10PCS2023Image
        or Cdg in CodeConcept.ICD10PCS2014Image
      )
      and Cdg.code in CodeConcept.TrastuzumabDeruxtecanIMG
    )
    and O.effective is not null
    and FHIRHelpers.ToDateTime(O.effective) >= "前次用藥開始日期"
    and FHIRHelpers.ToDateTime(O.effective) < "本次申請起始日期"
  )

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
//規則1:每次申請之療程以12週為限
define "規則1=每次申請之療程以12週為限":
  Reusable."HasMedicationPlanDurationWithin"(CodeConcept.L01FD04, 84)

/*規則2*/
define "規則2=Trastuzumab Deruxtecan和Sacituzumab Govitecan僅能擇一給付，不得互換":
  not (
    Reusable."HasMedicationUse"(CodeConcept.L01FX17)
    and Reusable."HasMedicationUse"(CodeConcept.L01FD04)
  )

//主要規定三
define "主要規定三":
"規則1=每次申請之療程以12週為限"
and "規則2=Trastuzumab Deruxtecan和Sacituzumab Govitecan僅能擇一給付，不得互換"


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and (
    "規則1=單獨使用於ER、PR皆陰性且具 HER2弱陽性表現之無法切除的局部晚期或轉移性乳癌病人" or
    "規則2=符合下列各項條件"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "ER陰性"
           then '● 條件1(ER)：ER陰性\n' else '') +
         (if "PR陰性"
           then '● 條件1(PR)：PR陰性\n' else '') +
         (if "基因檢測報告"
           then '● 條件1(基因)：已提供基因檢測報告\n' else '') +
         (if "HER2弱陽性(IHC 1+或IHC 2+/ISH-)表現"
           then '● 條件2(HER2)：HER2弱陽性(IHC1+或IHC2+/ISH-)表現\n' else '') +
         (if Reusable."ICD-10使用C50"
           then '● 條件3(ICD)：主要疾病ICD代碼使用C50\n' else '') +
         (if Reusable."醫令類別為1"
           then '● 條件3(醫令)：醫令類別為1(事前審查)\n' else '') +
         (if "病摘判斷無法切除"
           then '● 條件3(切除)：病摘已敘明無法切除\n' else '') +
         (if "癌症分期分數或結果為M>=1"
           then '● 條件3(分期)：癌症分期M≥1，確認為局部晚期或轉移性乳癌\n' else '') +
         (if "3個月內影像報告" and "3個月內有檢查報告"
           then '● 條件3(報告)：已同時提供3個月內影像報告及分子檢查報告\n' else '') +
         (if not "3個月內影像報告" and not "3個月內有檢查報告"
           then '● 條件3(報告)：無需附上3個月內影像報告及分子檢查報告\n' else '') +
         (if "2條件1=病人身體狀況良好(ECOG≦1)"
           then '● 條件4(ECOG)：病人身體狀況良好(ECOG≤1)\n' else '') +
         (if "2條件2=與化學療法併用"
           then '● 條件5：已接受至少一種化學療法治療並與本藥品併用\n' else '') +
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
  (if "規則1=每次申請之療程以12週為限" or "規則2=Trastuzumab Deruxtecan和Sacituzumab Govitecan僅能擇一給付，不得互換"
    then '<主要規定三：藥品使用規則>\n' +
         (if "規則1=每次申請之療程以12週為限"
           then '● 規則1：本次申請療程在12週(84天)以內\n' else '') +
         (if "規則2=Trastuzumab Deruxtecan和Sacituzumab Govitecan僅能擇一給付，不得互換"
           then '● 規則2：未與Sacituzumab Govitecan交替或混用，符合擇一給付規定\n' else '')
    else '')


//============================================
// 列出「不符合」項目判斷式 - 代碼或條件不符
//============================================

define function "不符合項目_代碼或條件不符"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if Reusable."初次申請" and (
    not "ER陰性" or
    not "PR陰性" or
    not "HER2弱陽性(IHC 1+或IHC 2+/ISH-)表現" or
    not Reusable."ICD-10使用C50" or
    not Reusable."醫令類別為1" or
    not "癌症分期分數或結果為M>=1" or
    not "2條件1=病人身體狀況良好(ECOG≦1)" or
    not "2條件2=與化學療法併用"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "ER陰性"
           then '▲ 條件1(ER)：ER非陰性，不符合單獨使用條件\n' else '') +
         (if not "PR陰性"
           then '▲ 條件1(PR)：PR非陰性，不符合單獨使用條件\n' else '') +
         (if not "HER2弱陽性(IHC 1+或IHC 2+/ISH-)表現"
           then '▲ 條件2(HER2)：HER2非弱陽性(非IHC1+或IHC2+/ISH-)\n' else '') +
         (if not Reusable."ICD-10使用C50"
           then '▲ ICD代碼檢核：主要疾病之ICD代碼未使用C50\n' else '') +
         (if not Reusable."醫令類別為1"
           then '▲ 條件3(醫令)：醫令類別非1，非事前審查申請\n' else '') +
         (if not "癌症分期分數或結果為M>=1"
           then '▲ 條件3(分期)：癌症分期M<1，未確認為局部晚期或轉移性乳癌\n' else '') +
         (if not "2條件1=病人身體狀況良好(ECOG≦1)"
           then '▲ 條件4(ECOG)：病人身體狀況不佳(ECOG>1)\n' else '') +
         (if not "2條件2=與化學療法併用"
           then '▲ 條件5：未接受化學療法治療，或未與本藥品併用\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 療程超標或條件不符
  (if not "規則1=每次申請之療程以12週為限"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則1：本次申請療程超過12週上限(84天)\n' + '\n'
    else '') +

  (if not "規則2=Trastuzumab Deruxtecan和Sacituzumab Govitecan僅能擇一給付，不得互換"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則2：曾與Sacituzumab Govitecan交替或混用，違反擇一給付規定\n' + '\n'
    else '')


//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
    not "基因檢測報告" or
    not "HER2弱陽性(IHC 1+或IHC 2+/ISH-)表現" or
    not "癌症分期分數或結果為M>=1" or
    not "病摘判斷無法切除" or
    ("3個月內有檢查報告" and not "3個月內影像報告") or
    (not "3個月內有檢查報告" and "3個月內影像報告")
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "基因檢測報告"
           then '▲ 條件1(基因)：未提供基因檢測報告\n' else '') +
         (if not "HER2弱陽性(IHC 1+或IHC 2+/ISH-)表現"
           then '▲ 條件2(HER2)：未提供HER2弱陽性檢測報告(IHC1+或IHC2+/ISH-)\n' else '') +
         (if not "癌症分期分數或結果為M>=1"
           then '▲ 條件3(分期)：未提供癌症分期資料(M分期)\n' else '') +
         (if not "病摘判斷無法切除"
           then '▲ 條件3(切除)：未於病摘中敘明無法切除\n' else '') +
         (if "3個月內有檢查報告" and not "3個月內影像報告"
           then '▲ 條件3(報告)：已提供分子檢查報告但缺少3個月內影像報告，兩者須同時提供\n' else '') +
         (if not "3個月內有檢查報告" and "3個月內影像報告"
           then '▲ 條件3(報告)：已提供影像報告但缺少3個月內分子檢查報告，兩者須同時提供\n' else '') +
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

define "乳癌TrastuzumabDeruxtecanHER2弱陽性申請結果_布林":
  case
    when Reusable."初次申請" then (
      "主要規定一" and
      "主要規定三"
    )
    when Reusable."續用申請" then
      "主要規定二"
    else false
  end

define "乳癌TrastuzumabDeruxtecanHER2弱陽性申請之CQL檢核結果":
  if (
    Reusable."初次申請" and
    "主要規定一" and
    "主要規定三"
  )
  then '✓通過：初次使用－轉移性乳癌(HER2弱陽性)Trastuzumab Deruxtecan用藥申請'

  else if (
    Reusable."續用申請" and
    "主要規定二"
  )
  then '✓通過：續用－轉移性乳癌(HER2弱陽性)Trastuzumab Deruxtecan用藥申請'

  else if Reusable."初次申請"
  then '✖不通過：初次使用－轉移性乳癌(HER2弱陽性)Trastuzumab Deruxtecan用藥申請'

  else if Reusable."續用申請"
  then '✖不通過：續用－轉移性乳癌(HER2弱陽性)Trastuzumab Deruxtecan用藥申請'

  else '✖不通過：無法判定申請類型－轉移性乳癌(HER2弱陽性)Trastuzumab Deruxtecan用藥申請'


//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 轉移性乳癌之Trastuzumab Deruxtecan申請審核報告 ===\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 代碼或條件不符】\n' +
  (if "不符合項目_代碼或條件不符"() = '' then '無\n' else "不符合項目_代碼或條件不符"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【申請結果】\n' +
  "乳癌TrastuzumabDeruxtecanHER2弱陽性申請之CQL檢核結果" +
  '\n===============================================\n'
