//乳癌_Larotrectinib給付規定
library BCLarotrectinibRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include BCCodeConcept version '1.0.0' called CodeConcept

include BCReusable version '1.0.0' called Reusable

context Patient


//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/
//1條件1:NTRK 基因融合且無已知的後天阻抗性突變

define "1條件1=NTRK基因融合且無已知的後天阻抗性突變":
  exists (
    [Observation] RasO
    where RasO.status = 'final'
    and exists (
      RasO.code.coding ObsCodeCoding
      where ObsCodeCoding.code = '69548-6'
      and ObsCodeCoding in CodeConcept.LOINC
    )
    and exists (
      RasO.component ComponentRecord
      where exists (
        ComponentRecord.code.coding ComponentCodeCoding
        where ComponentCodeCoding.code in CodeConcept.LarotrectinibGeneTest
      )
    )
    and RasO.value is not null
    and RasO.value is FHIR.string
    and Matches((RasO.value as FHIR.string).value, '(?i).*fusion且無後天阻抗性突變.*')
  )


//1條件2:轉移性實體腫瘤
define "ICD代碼檢核_布林值": Reusable."ICD-10使用C50"


define "醫令類別為1_布林值": Reusable."醫令類別為1"

define "三個月內有影像檢查報告":
  Reusable."HasRecentImageReport"("本次申請起始日期", 90)



define "癌症分期分數或結果為M≠0":
  Reusable."癌症分期分數或結果為M≠0"



define "三個月內有檢查報告":
  exists (
    [DiagnosticReport] O2
    where exists (
      O2.code.coding Cdg
      where Cdg in CodeConcept.LOINC
      and Cdg.code in CodeConcept.DiagnosticReport
    )
    and O2.effective is not null
    and FHIRHelpers.ToDateTime(O2.effective) >= "本次申請起始日期" - 90 days
    and FHIRHelpers.ToDateTime(O2.effective) <= "本次申請起始日期"
  ) 



define "1條件2=轉移性實體腫瘤":
  Reusable."ICD-10使用C50"
  and Reusable."醫令類別為1"
  and "癌症分期分數或結果為M≠0"
  and (
    ("三個月內有影像檢查報告" and "三個月內有檢查報告")
    or not ("三個月內有影像檢查報告" and "三個月內有檢查報告")
  )


//1條件3:手術切除極可能造成嚴重病症
define "1條件3=病摘說明手術切除會造成嚴重病症":
    exists (
        [Claim] C
        where exists (
            C.diagnosis D
            where exists (
                D.type.text T
                where Matches(T.value, '(?i).*(手術切除會造成嚴重病症).*')
            )
        )
    )
    

//1條件4:沒有合適的替代治療選項
define "1條件4=病摘說明沒有合適的替代治療選項":
    exists (
        [Claim] C
        where exists (
            C.diagnosis D
            where exists (
                D.type.text T
                where Matches(T.value, '(?i).*(沒有合適的替代治療選項).*')
            )
        )
    )

define "規則1":
"1條件1=NTRK基因融合且無已知的後天阻抗性突變" 
and "1條件2=轉移性實體腫瘤"
and "1條件3=病摘說明手術切除會造成嚴重病症"
and "1條件4=病摘說明沒有合適的替代治療選項"


/*規則2*/ 
//同 1條件1=NTRK基因融合且無已知的後天阻抗性突變
//需檢附NTRK基因融合檢測報告


/*規則3*/

//3條件1:檢核未滿18 歲與否(符合採條件2不符合採條件3)
define "年齡計算用申請日期":
  date from "本次申請起始日期"

define "申請日時病人年齡歲數":
  if Patient.birthDate is null or "年齡計算用申請日期" is null then null
  else difference in years between
    FHIRHelpers.ToDate(Patient.birthDate)
    and "年齡計算用申請日期"

define "3條件1=滿18歲":
  if "申請日時病人年齡歲數" is null then false
  else "申請日時病人年齡歲數" >= 18

//3條件2:曾接受一線治療後無效或復發
define "3條件2=曾接受一線治療後無效或復發":
  Reusable."醫令類別為1"
  and exists (
    [MedicationRequest] MRChemo
    where MRChemo.intent = 'order'
    and exists (
      MRChemo.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
      and Cdg.code in CodeConcept."Larotrectinib一線治療"
    )
    and Reusable."HasValidTiming"(MRChemo)
    and (end of (MRChemo.dosageInstruction[0].timing.repeat.bounds as Period)) < "本次申請起始日期"
  )
  and Reusable."用藥線別≠1"

//3條件3:分泌型乳腺癌
define "3條件3=分泌型乳腺癌":
  Reusable."ICD-10使用C50"
  and "癌症分期分數或結果為M≠0"
  and (
    ("三個月內有影像檢查報告" and "三個月內有檢查報告")
    or not ("三個月內有影像檢查報告" and "三個月內有檢查報告")
  )

//3條件4-1:先前曾接受過前導性化學治療
define "3條件4-1=先前曾接受過前導性化學治療":
  Reusable."醫令類別為1"
  and Reusable."HasPriorMedicationUse"(CodeConcept.L01EX12, CodeConcept."Larotrectinib前導性化學治療")
  and Reusable."用藥線別≠1"


//3條件4-2:術後輔助性化學治療
define "3條件4-2=術後輔助性化學治療":
  Reusable."醫令類別為1"
  and Reusable."HasPriorMedicationUse"(CodeConcept.L01EX12, CodeConcept."Larotrectinib術後輔助性化學治療")
  and Reusable."用藥線別≠1"


//3條件4-3:轉移性化學治療
define "3條件4-3=轉移性化學治療":
  Reusable."醫令類別為1"
  and Reusable."HasPriorMedicationUse"(CodeConcept.L01EX12, CodeConcept."Larotrectinib轉移性化學治療")
  and Reusable."用藥線別≠1"

define "3條件4=三項擇一":
"3條件4-1=先前曾接受過前導性化學治療"
or "3條件4-2=術後輔助性化學治療"
or "3條件4-3=轉移性化學治療"


define "規則3":
if "3條件1=滿18歲"
then "3條件2=曾接受一線治療後無效或復發"
else "3條件3=分泌型乳腺癌" and "3條件4=三項擇一"


//主要規定一
define "主要規定一":
"規則1" and "規則3"


//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.L01EX12)

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

//影像證據顯示病情有無惡化
// 取得前次治療紀錄（最近一次已完成的治療）
define "前次治療紀錄":
  Reusable."LatestCompletedMedicationOrderBefore"(CodeConcept.L01EX12, "本次申請起始日期")

// 前次用藥開始日期
define "前次用藥開始日期":
  Reusable."GetStartTime"("前次治療紀錄")

// 條件1:影像證據顯示病情有無惡化
define "規則1=影像證據顯示病情有無惡化":
  Reusable."HasImageReportBetweenPreviousTreatmentAndCurrentApply"(CodeConcept.L01EX12)


// 主要規定二
define "主要規定二":
Reusable."續用註記為2"
and Reusable."醫令類別為1"
and "本次申請紀錄" is not null
and "規則1=影像證據顯示病情有無惡化"


//============================================
// 主要規定三：藥品使用規則
//============================================

//每次申請之療程以12週為限
define "主要規定三=每次申請之療程以12週為限":
  Reusable."HasMedicationPlanDurationWithin"(CodeConcept.L01EX12, 84)
  and Reusable."醫令類別為1"


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and "主要規定一"
    then '<主要規定一：初次使用條件>\n' +
         (if "1條件1=NTRK基因融合且無已知的後天阻抗性突變"
           then '● 條件1：NTRK基因融合且無已知的後天阻抗性突變\n' else '') +
         (if "ICD代碼檢核_布林值"
           then '● 條件2-0：ICD代碼為C50\n' else '') +
         (if "癌症分期分數或結果為M≠0"
           then '● 條件2-1：癌症分期結果為M≠0（轉移性）\n' else '') +
         (if "1條件3=病摘說明手術切除會造成嚴重病症"
           then '● 條件3：病摘說明手術切除會造成嚴重病症\n' else '') +
         (if "1條件4=病摘說明沒有合適的替代治療選項"
           then '● 條件4：病摘說明沒有合適的替代治療選項\n' else '') +
         (if "3條件1=滿18歲"
           then '● 年齡條件：滿18歲\n' +
                (if "3條件2=曾接受一線治療後無效或復發"
                  then '● 規則3（成人）：曾接受一線治療後無效或復發\n' else '')
           else '● 年齡條件：未滿18歲\n' +
                (if "3條件3=分泌型乳腺癌"
                  then '● 規則3-3：分泌型乳腺癌\n' else '') +
                (if "3條件4-1=先前曾接受過前導性化學治療"
                  then '● 規則3-4-1：曾接受前導性化學治療\n' else '') +
                (if "3條件4-2=術後輔助性化學治療"
                  then '● 規則3-4-2：曾接受術後輔助性化學治療\n' else '') +
                (if "3條件4-3=轉移性化學治療"
                  then '● 規則3-4-3：曾接受轉移性化學治療\n' else '')) +
         '\n'
    else '') +

  // 主要規定二：續用條件
  (if Reusable."續用申請" and "主要規定二"
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '● 續用規則1：已檢附前次治療後影像學報告，確認無惡化\n' +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則
  (if "主要規定三=每次申請之療程以12週為限"
    then '<主要規定三：藥品使用規則>\n' +
         '● 規則3：每次申請之療程≤12週（84天）\n' +
         '\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 代碼或條件不符
//============================================

define function "不符合項目_代碼或條件不符"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if Reusable."初次申請" and (
    not "ICD代碼檢核_布林值" or
    not "癌症分期分數或結果為M≠0"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "ICD代碼檢核_布林值"
           then '▲ 條件2-0：主要疾病之ICD代碼未使用C50\n' else '') +
         (if not "癌症分期分數或結果為M≠0"
           then '▲ 條件2-1：癌症分期結果非M≠0（非轉移性）\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 代碼條件不符
  (if not "主要規定三=每次申請之療程以12週為限"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則3：每次申請之療程超過12週（84天）\n' +
         '\n'
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
    not "1條件1=NTRK基因融合且無已知的後天阻抗性突變" or
    not "1條件3=病摘說明手術切除會造成嚴重病症" or
    not "1條件4=病摘說明沒有合適的替代治療選項" or
    not "規則3"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "1條件1=NTRK基因融合且無已知的後天阻抗性突變"
           then '▲ 條件1：未提供NTRK基因融合且無後天阻抗性突變之檢測結果\n' else '') +
         (if not "1條件3=病摘說明手術切除會造成嚴重病症"
           then '▲ 條件3：病摘未說明手術切除會造成嚴重病症\n' else '') +
         (if not "1條件4=病摘說明沒有合適的替代治療選項"
           then '▲ 條件4：病摘未說明沒有合適的替代治療選項\n' else '') +
         (if not "規則3"
           then if "3條件1=滿18歲"
                then '▲ 規則3（成人）：未提供曾接受一線治療後無效或復發之紀錄\n'
                else '▲ 規則3（兒童）：' +
                     (if not "3條件3=分泌型乳腺癌"
                       then '未符合分泌型乳腺癌條件；' else '') +
                     (if not "3條件4=三項擇一"
                       then '未提供前導性、術後輔助性或轉移性化學治療紀錄\n' else '\n')
           else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and not "主要規定二"
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '▲ 續用規則1：未提供前次治療後影像學報告或顯示疾病惡化\n' +
         '\n'
    else '')

//============================================
// 審核結果
//============================================

define "乳癌Larotrectinib申請結果_布林":
  case
    when Reusable."初次申請" then (
      "主要規定一" and
      "主要規定三=每次申請之療程以12週為限"
    )
    when Reusable."續用申請" then (
      "主要規定二" and
      "主要規定三=每次申請之療程以12週為限"
    )
    else false
  end

define "乳癌Larotrectinib申請之CQL檢核結果":
  if (
    Reusable."初次申請" and
    "主要規定一" and
    "主要規定三=每次申請之療程以12週為限"
  )
  then '✓通過：初次使用－乳癌 Larotrectinib 用藥申請'

  else if (
    Reusable."續用申請" and
    "主要規定二" and
    "主要規定三=每次申請之療程以12週為限"
  )
  then '✓通過：續用－乳癌 Larotrectinib 用藥申請'

  else if Reusable."初次申請"
  then '✖不通過：初次使用－乳癌 Larotrectinib 用藥申請'

  else if Reusable."續用申請"
  then '✖不通過：續用－乳癌 Larotrectinib 用藥申請'

  else '✖不通過：無法判定申請類型－乳癌 Larotrectinib 用藥申請'

//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 乳癌之 Larotrectinib 申請審核報告 ===\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【年齡檢核】' +
  '申請日時病人年齡歲數：' +
  Coalesce(ToString("申請日時病人年齡歲數"), '無法計算') + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 代碼或條件不符】\n' +
  (if "不符合項目_代碼或條件不符"() = '' then '無\n' else "不符合項目_代碼或條件不符"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【申請結果】\n' +
  "乳癌Larotrectinib申請之CQL檢核結果" +
  '\n===============================================\n'
