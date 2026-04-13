//早期乳癌_Pertuzumab給付規定

library BCPertuzumabRule1 version '1.0.0'

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

//條件1-1:具腋下淋巴結轉移但無遠處臟器轉移之早期乳癌(M=0)
//條件1-1-1
define "條件1-1-1=3個月內影像報告":
Reusable."HasRecentImageReport"("本次申請起始日期", 90)


//條件1-1-2
define "條件1-1-2=癌症分期分數或結果為N≠0且M=0":
  exists (
    [Observation] O
      where exists (
        O.code.coding Cdg
          where Cdg.code = '399390009'
            and Cdg in CodeConcept.SNOMED
      )
        and O.value is not null
        and O.value is FHIR.string
        and Matches((O.value as FHIR.string).value, '.*M[0].*')
        and Matches((O.value as FHIR.string).value, '.*N[1-9][a-zA-Z]?.*')
  )

//條件1-1-3/條件1-2-3(檢查報告)
define "條件1-1-3/條件1-2-3=3個月內有檢查報告":
Reusable."HasRecentMolecularReport"("本次申請起始日期", 90)


define "條件1-1=具腋下淋巴結轉移但無遠處臟器轉移之早期乳癌(M=0)":
  "ICD代碼檢核_布林值" 
  and "醫令類別為1_布林值" 
  and "Pertuzumab申請"
  and "條件1-1-2=癌症分期分數或結果為N≠0且M=0"
  or ("條件1-1-1=3個月內影像報告" and "條件1-1-3/條件1-2-3=3個月內有檢查報告")


//條件1-2:具腋下淋巴結轉移但無遠處臟器轉移之早期乳癌(M=1但為骨轉移)
//條件1-2-1
define "條件1-2-1=3個月內影像報告(為骨轉移)":
  exists (
    [DiagnosticReport] O
    where exists (
      O.code.coding Cdg
      where (
        Cdg in CodeConcept.ICD10PCS2023Image
        or Cdg in CodeConcept.ICD10PCS2014Image
      )
      and Cdg.code in CodeConcept.ImageCodes
    )
    and O.effective is not null
    and FHIRHelpers.ToDateTime(O.effective) >= "本次申請起始日期" - 90 days
    and FHIRHelpers.ToDateTime(O.effective) <= "本次申請起始日期"
    and O.conclusion is not null
    and Matches(O.conclusion, '(?i).*(顯示僅具有骨轉移無其他轉移).*')
  ) 


//條件1-2-2
define "條件1-2-2=癌症分期分數或結果為N≠0且M=1":
  exists (
    [Observation] O
      where exists (
        O.code.coding Cdg
          where Cdg.code = '399390009'
            and Cdg in CodeConcept.SNOMED
      )
        and O.value is not null
        and O.value is FHIR.string
        and Matches((O.value as FHIR.string).value, '.*M[1].*')
        and Matches((O.value as FHIR.string).value, '.*N[1-9][a-zA-Z]?.*')
  )


define "條件1-2=具腋下淋巴結轉移但無遠處臟器轉移之早期乳癌(M=1但為骨轉移)":
  "醫令類別為1_布林值" 
  and "Pertuzumab申請"
  and "條件1-2-2=癌症分期分數或結果為N≠0且M=1"
  and "條件1-2-1=3個月內影像報告(為骨轉移)" 
  or "條件1-1-3/條件1-2-3=3個月內有檢查報告"

define "條件1":
  "條件1-1=具腋下淋巴結轉移但無遠處臟器轉移之早期乳癌(M=0)" 
  or "條件1-2=具腋下淋巴結轉移但無遠處臟器轉移之早期乳癌(M=1但為骨轉移)"


//條件2:具HER2過度表現(IHC3+或FISH+)
define "條件2=檢驗檢查-具HER2過度表現":
  Reusable."HasHER2OverexpressionTest"

define "條件2=基因檢測-具HER2過度表現":
  Reusable."HasHER2OverexpressionGene"

define "條件2=具HER2過度表現":
  "條件2=檢驗檢查-具HER2過度表現"
  or "條件2=基因檢測-具HER2過度表現"

//規則1
define "規則1":
"條件1" and "條件2=具HER2過度表現"


/*規則2*/
//條件1:與trastuzumab（限使用Ogivri、Herzuma、Eirgasun、Herceptin、Kanjinti）併用
define "條件1=與trastuzumab（限使用Ogivri、Herzuma、Eirgasun、Herceptin、Kanjinti）併用":
  Reusable."HasConcurrentMedicationOrder"(CodeConcept."L01FD02", CodeConcept."Trastuzumab併用藥物")
  and Reusable."醫令類別為1"


//條件2:與化學療法併用
define "條件2=與化學療法併用":
  Reusable."HasConcurrentMedicationOrder"(CodeConcept."L01FD02", CodeConcept."化學療法")
  and Reusable."醫令類別為1"


//規則2
define "規則2":
"條件1=與trastuzumab（限使用Ogivri、Herzuma、Eirgasun、Herceptin、Kanjinti）併用"
and "條件2=與化學療法併用"


//主要規定一
define "主要規定一": "規則1" and "規則2"

//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

//條件1:每24週須檢附療效評估資料再次申請，若疾病有惡化情形即不應再行申請
// 本次申請紀錄（以最新一筆申請作為本次申請）
define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.L01FD02)

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

// 前次申請紀錄（本次申請之前最近一次的申請）
define "前次申請紀錄":
  Reusable."LatestMedicationPlanBefore"(CodeConcept.L01FD02, "本次申請起始日期")

// 檢查本次申請療程長度是否在24週內
define "規則1-1=每24週須再次申請並檢附療效評估資料":
  Reusable."醫令類別為1" 
  and Reusable."續用註記為2"
  and "本次申請紀錄" is not null
  and Reusable."HasMedicationPlanPeriodWithinDays"(CodeConcept.L01FD02, 168)


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
and Reusable."醫令類別為1"
and "本次申請紀錄" is not null
and "規則1-1=每24週須再次申請並檢附療效評估資料"
and "規則1-2=疾病有惡化情形須停止使用"



//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/

//條件1:使用於術前輔助治療，經外科手術後達病理上完全緩解者（pCR）(病摘或病理報告結果須至少一項符合)
//條件1-1
define "條件1-1=經外科手術後達病理上完全緩解者（pCR）":
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
      and (O2.conclusion is not null
        or Matches(O2.conclusion, '(?i).*(外科手術後達病理上完全緩解（pCR）).*'))
  )
  or exists (
    [Claim] C
    where exists (
        C.diagnosis D
        where exists (
            D.type.text T
            where Matches(T.value, '(?i).*(外科手術後達病理上完全緩解（pCR）).*')
          )
      )
  )


//條件1-2:此藥物之申請藥品為術前治療，影像檢查日期為處方起始日期後
define "條件1-2=此藥物之申請藥品為術前治療，影像檢查日期為處方起始日期後":
  Reusable."醫令類別為1"
  and exists (
    [MedicationRequest] MRApply
    where MRApply.intent = 'plan'
    and exists (
      MRApply.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.L01FD02
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
      and FHIRHelpers.ToDateTime(O.effective) > FHIRHelpers.ToDateTime((MRApply.dosageInstruction[0].timing.repeat.bounds as Period).start)
    )
  )


//條件1-3:得繼續使用至18個療程為上限
define "條件1-3=得繼續使用至18個療程為上限":
  Count(
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
              and Cdg.code in CodeConcept.L01FD02
        )
  ) <= 18


define "條件1=使用於術前輔助治療，經外科手術後達病理上完全緩解者（pCR）":
"條件1-1=經外科手術後達病理上完全緩解者（pCR）"
and "條件1-2=此藥物之申請藥品為術前治療，影像檢查日期為處方起始日期後"
and "條件1-3=得繼續使用至18個療程為上限"


define "條件2=若未接受術前輔助治療，即先行手術者，可給予術後輔助治療":
"條件1-2=此藥物之申請藥品為術前治療，影像檢查日期為處方起始日期後"
and "條件1-3=得繼續使用至18個療程為上限"

//規則1
define "用藥規則1":
"條件1=使用於術前輔助治療，經外科手術後達病理上完全緩解者（pCR）"
or "條件2=若未接受術前輔助治療，即先行手術者，可給予術後輔助治療"


/*規則2*/
//I、II、III總療程以18個療程為上限(Ｉ：pertuzumab 與trastuzumab 併用Ⅱ：trastuzumabⅢ：pertuzumab 與trastuzumab 皮下注射複方製劑(如Phesgo))
define "用藥規則2=總療程以18個療程為上限":
  Count(
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
              and Cdg.code in CodeConcept."Pertuzumab併用藥物"
        )
  ) <= 18


// 主要規定三
define "主要規定三": "用藥規則1" and "用藥規則2=總療程以18個療程為上限"


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and (
    "條件1" or 
    "條件2=具HER2過度表現" or 
    "條件1=與trastuzumab（限使用Ogivri、Herzuma、Eirgasun、Herceptin、Kanjinti）併用" or 
    "條件2=與化學療法併用"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "ICD代碼檢核_布林值" 
           then '● 規則1-0：ICD代碼為C50\n' else '') +
         (if "條件1-1-1=3個月內影像報告" 
           then '● 規則1-1-1：3個月內影像報告\n' else '') +
         (if "條件1-1-2=癌症分期分數或結果為N≠0且M=0" 
           then '● 規則1-1-2：癌症分期為N≠0且M=0（腋下淋巴結轉移但無遠處臟器轉移）\n' else '') +
         (if "條件1-1-3/條件1-2-3=3個月內有檢查報告" 
           then '● 規則1-1-3：3個月內有檢查報告\n' else '') +
         (if "條件1-2-1=3個月內影像報告(為骨轉移)" 
           then '● 規則1-2-1：3個月內影像報告顯示僅具有骨轉移無其他轉移\n' else '') +
         (if "條件1-2-2=癌症分期分數或結果為N≠0且M=1" 
           then '● 規則1-2-2：癌症分期為N≠0且M=1（腋下淋巴結轉移且僅骨轉移）\n' else '') +
         (if "Pertuzumab申請" 
           then '● Pertuzumab申請\n' else '') +
         (if "條件2=具HER2過度表現" 
           then '● 規則1-條件2：具HER2過度表現（IHC3+或FISH+）\n' else '') +
         (if "條件1=與trastuzumab（限使用Ogivri、Herzuma、Eirgasun、Herceptin、Kanjinti）併用" 
           then '● 規則2-條件1：與trastuzumab（限使用Ogivri、Herzuma、Eirgasun、Herceptin、Kanjinti）併用\n' else '') +
         (if "條件2=與化學療法併用" 
           then '● 規則2-條件2：與化學療法併用\n' else '') +
         '\n'
    else '') +
  
  // 主要規定二：續用條件
  (if Reusable."續用申請" and (
    "規則1-1=每24週須再次申請並檢附療效評估資料" or 
    "規則1-2=疾病有惡化情形須停止使用"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if "規則1-1=每24週須再次申請並檢附療效評估資料" 
           then '● 續用規則1-1：於24週內再次申請並檢附療效評估資料\n' else '') +
         (if "規則1-2=疾病有惡化情形須停止使用" 
           then '● 續用規則1-2：已檢附前次治療後影像學報告，確認無惡化\n' else '') +
         '\n'
    else '') +
  
  // 主要規定三：藥品使用規則
  (if "用藥規則1" or "用藥規則2=總療程以18個療程為上限"
    then '<主要規定三：藥品使用規則>\n' +
         (if "條件1-1=經外科手術後達病理上完全緩解者（pCR）" 
           then '● 規則3-1-1：術前輔助治療後，經外科手術後達病理上完全緩解者（pCR）\n' else '') +
         (if "條件1-2=此藥物之申請藥品為術前治療，影像檢查日期為處方起始日期後" 
           then '● 規則3-1-2：申請藥品為術前治療或術後輔助治療\n' else '') +
         (if "條件1-3=得繼續使用至18個療程為上限" 
           then '● 規則3-1-3：使用療程≤18個療程\n' else '') +
         (if "用藥規則2=總療程以18個療程為上限" 
           then '● 規則3-2：總療程（含pertuzumab與trastuzumab併用、trastuzumab單用、或複方製劑）≤18個療程\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 代碼或條件不符
//============================================

define function "不符合項目_代碼或條件不符"():
  // 主要規定一：初次使用條件 - 代碼條件不符
  (if Reusable."初次申請" and (
    not "ICD代碼檢核_布林值" or 
    (not "條件1-1-2=癌症分期分數或結果為N≠0且M=0" and not "條件1-2-2=癌症分期分數或結果為N≠0且M=1")
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "ICD代碼檢核_布林值" 
           then '▲ 規則1-0：主要疾病之ICD代碼未使用C50\n' else '') +
         (if not "條件1-1-2=癌症分期分數或結果為N≠0且M=0" and not "條件1-2-2=癌症分期分數或結果為N≠0且M=1" 
           then '▲ 規則1-條件1：癌症分期不符合（需為N≠0且M=0，或N≠0且M=1但僅骨轉移）\n' else '') +
         '\n'
    else '') +
  
  // 主要規定三：藥品使用規則 - 代碼條件不符
  (if not "條件1-3=得繼續使用至18個療程為上限" or not "用藥規則2=總療程以18個療程為上限"
    then '<主要規定三：藥品使用規則>\n' +
         (if not "條件1-3=得繼續使用至18個療程為上限" 
           then '▲ 規則3-1-3：使用療程超過18個療程\n' else '') +
         (if not "用藥規則2=總療程以18個療程為上限" 
           then '▲ 規則3-2：總療程（含pertuzumab與trastuzumab併用、trastuzumab單用、或複方製劑）超過18個療程\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
    not "Pertuzumab申請" or 
    not ("條件1-1-1=3個月內影像報告" or "條件1-2-1=3個月內影像報告(為骨轉移)" or "條件1-1-3/條件1-2-3=3個月內有檢查報告") or 
    not "條件2=具HER2過度表現" or 
    not "條件1=與trastuzumab（限使用Ogivri、Herzuma、Eirgasun、Herceptin、Kanjinti）併用" or 
    not "條件2=與化學療法併用"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "Pertuzumab申請" 
           then '▲ 未申請Pertuzumab\n' else '') +
         (if not ("條件1-1-1=3個月內影像報告" or "條件1-2-1=3個月內影像報告(為骨轉移)" or "條件1-1-3/條件1-2-3=3個月內有檢查報告") 
           then '▲ 規則1-條件1：未提供3個月內影像報告或檢查報告\n' else '') +
         (if not "條件2=具HER2過度表現" 
           then '▲ 規則1-條件2：未提供HER2過度表現檢測資料（需IHC3+或FISH+）\n' else '') +
         (if not "條件1=與trastuzumab（限使用Ogivri、Herzuma、Eirgasun、Herceptin、Kanjinti）併用" 
           then '▲ 規則2-條件1：未與trastuzumab（限使用Ogivri、Herzuma、Eirgasun、Herceptin、Kanjinti）併用\n' else '') +
         (if not "條件2=與化學療法併用" 
           then '▲ 規則2-條件2：未與化學療法併用\n' else '') +
         '\n'
    else '') +
  
  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (
    not "規則1-1=每24週須再次申請並檢附療效評估資料" or 
    not "規則1-2=疾病有惡化情形須停止使用"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if not "規則1-1=每24週須再次申請並檢附療效評估資料" 
           then '▲ 續用規則1-1：未於24週內再次申請或未檢附療效評估資料\n' else '') +
         (if not "規則1-2=疾病有惡化情形須停止使用" 
           then '▲ 續用規則1-2：未提供前次治療後影像學報告或顯示疾病惡化\n' else '') +
         '\n'
    else '') +
  
  // 主要規定三：藥品使用規則 - 必要資料未填寫
  (if not "條件1-2=此藥物之申請藥品為術前治療，影像檢查日期為處方起始日期後"
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則3-1-2：未提供術前治療或術後輔助治療相關影像檢查資料\n' +
         '\n'
    else '')


//============================================
// 審核結果
//============================================

define "乳癌Pertuzumab申請結果_布林":
  case
    when Reusable."初次申請" then (
      "規則1" and
      "規則2" and
      "用藥規則1" and
      "用藥規則2=總療程以18個療程為上限"
    )
    when Reusable."續用申請" then (
      "規則1-1=每24週須再次申請並檢附療效評估資料" and
      "規則1-2=疾病有惡化情形須停止使用" and
      "用藥規則1" and
      "用藥規則2=總療程以18個療程為上限"
    )
    else false
  end

define "乳癌Pertuzumab申請之CQL檢核結果":
  if (
    Reusable."初次申請" and 
    "規則1" and
    "規則2" and
    "用藥規則1" and
    "用藥規則2=總療程以18個療程為上限"
  )
  then '✓通過：初次使用－早期乳癌 Pertuzumab 用藥申請'

  else if (
    Reusable."續用申請" and
    "規則1-1=每24週須再次申請並檢附療效評估資料" and
    "規則1-2=疾病有惡化情形須停止使用" and
    "用藥規則1" and
    "用藥規則2=總療程以18個療程為上限"
  )
  then '✓通過：續用－早期乳癌 Pertuzumab 用藥申請'
  
  else if Reusable."初次申請"
  then '✖不通過：初次使用－早期乳癌 Pertuzumab 用藥申請'
  
  else if Reusable."續用申請"
  then '✖不通過：續用－早期乳癌 Pertuzumab 用藥申請'
  
  else '✖不通過：無法判定申請類型－早期乳癌 Pertuzumab 用藥申請'

//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 早期乳癌之Pertuzumab 申請審核報告 ===\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 代碼或條件不符】\n' +
  (if "不符合項目_代碼或條件不符"() = '' then '無\n' else "不符合項目_代碼或條件不符"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【申請結果】\n' +
  "乳癌Pertuzumab申請之CQL檢核結果" +
  '\n===============================================\n'
