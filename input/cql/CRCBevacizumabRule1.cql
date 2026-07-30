//大腸直腸癌_Bevacizumab給付規定(轉移性大腸或直腸癌患者的第一線治療)
library CRCBevacizumabRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include CRCCodeConcept version '1.0.0' called CodeConcept

include CRCReusable version '1.0.0' called Reusable

context Patient


//============================================
// 主要規定一：初次使用條件
//============================================

// 本次申請紀錄（以最新一筆申請作為本次申請）
define "本次申請紀錄":
  Last(
    [MedicationRequest] MR
      where MR.intent = 'plan'
        and MR.dosageInstruction[0].timing.repeat.bounds is Period
      sort by FHIRHelpers.ToDateTime((dosageInstruction[0].timing.repeat.bounds as Period).start)
  )

define "本次申請起始日期":
  FHIRHelpers.ToDateTime(("本次申請紀錄".dosageInstruction[0].timing.repeat.bounds as Period).start)

/*規則1*/
//條件1
define "1規則1-1=Bevacizumab與FOLFIRI（Folinicacid/5-fluorouracil/irinotecan）併用":
  Reusable."HasConcurrentMedicationOrders2"(CodeConcept.L01FG01, CodeConcept.L01BC02, CodeConcept.L01CE02)
  and Reusable."醫令類別為1"


//條件2
define "1規則1-2=Bevacizumab與FOLFOX（Folinicacid/5-fluorouracil/oxaliplatin）併用":
  Reusable."HasConcurrentMedicationOrders2"(CodeConcept.L01FG01, CodeConcept.L01BC02, CodeConcept.L01XA03)
  and Reusable."醫令類別為1"

//條件3
define "1規則1-3=Bevacizumab與5-fluorouracil/leucovorin的化學療法合併使用":
  Reusable."HasConcurrentMedicationOrders2"(CodeConcept.L01FG01, CodeConcept.L01BC02, CodeConcept.V03AF03)
  and Reusable."醫令類別為1"



define "1規則1=化學療法合併使用":
  "1規則1-1=Bevacizumab與FOLFIRI（Folinicacid/5-fluorouracil/irinotecan）併用"
  or "1規則1-2=Bevacizumab與FOLFOX（Folinicacid/5-fluorouracil/oxaliplatin）併用"
  or "1規則1-3=Bevacizumab與5-fluorouracil/leucovorin的化學療法合併使用"

/*規則2*/
//條件1
//Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"
define "ICD代碼檢核_布林值": Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"

//條件2
define "1規則2-2=三個月內有影像報告":
  Reusable."HasRecentImageReport"(CodeConcept.ImageReportCode, "本次申請起始日期")

//條件3
define "1規則2-3=三個月內有檢查報告":
  Reusable."HasRecentDiagnosticReport"(CodeConcept.DiagnosticReportCode, "本次申請起始日期")

//條件4
define "1規則2-4=癌症分期分數或結果為M>=1":
  Reusable."癌症分期分數或結果為M>=1"

//條件5
define "1規則2-5=用藥線別為第一線":
  Reusable."HasLineOfTherapy"('1')

define "1規則2=轉移性直腸結腸癌病患之第一線治療":
 ("1規則2-2=三個月內有影像報告"
  or "1規則2-3=三個月內有檢查報告")
  and "1規則2-4=癌症分期分數或結果為M>=1"
  and "1規則2-5=用藥線別為第一線"

define "主要規定一":
  Reusable."初次申請" and
  "1規則1=化學療法合併使用" 
  and "1規則2=轉移性直腸結腸癌病患之第一線治療"
  and Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"

//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

/*規則1*/
define "2規則1=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用":
  exists (
    [MedicationRequest] MRPlan
     where MRPlan.intent = 'plan'
     and exists (
        MRPlan.medication.coding Cdg
        where Cdg in CodeConcept.NHIMedication
        and Cdg.code in CodeConcept.L01FG01
      )
  and exists (
    [DiagnosticReport] Report
     where exists (
      Report.code.coding Cdg
        where (
          Cdg in CodeConcept.ICD10PCS2023Image
          or Cdg in CodeConcept.ICD10PCS2014Image
        )
        and Cdg.code in CodeConcept.ImageReportCode
      )
      and Report.effective is not null
      and FHIRHelpers.ToDateTime(Report.effective) >= "本次申請起始日期" - 90 days
      and FHIRHelpers.ToDateTime(Report.effective) <= "本次申請起始日期"
      )
      
    )
  and Reusable."醫令類別為1"

define "主要規定二":
  Reusable."續用申請" and
  "2規則1=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用"


//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
define "3規則1=每次申請事前審查之療程以18週為限":
  Reusable."HasMedicationPlanDurationWithin"(CodeConcept.L01FG01, 126)
/*規則2*/
define "3規則2=使用總療程以36週為上限":
  Reusable."HasMedicationTotalDurationWithin"(CodeConcept.L01FG01, 252)


/*規則3*/
//條件1
define "3規則3-1=使用cetuximab、panitumumab藥品":
  Reusable."HasMedicationUse"(CodeConcept.L01FE)

//條件2
define "3規則3-2=本藥品未與cetuximab、panitumumab併用":
  Reusable."IsMedicationPlan"("本次申請紀錄", CodeConcept.L01FG01)
  and not Reusable."HasConcurrentMedicationPlan"(CodeConcept.L01FG01, CodeConcept.L01FE)

define "3規則3=本藥品不得與cetuximab, panitumumab併用":
  not "3規則3-1=使用cetuximab、panitumumab藥品"
  or "3規則3-2=本藥品未與cetuximab、panitumumab併用"

define "主要規定三":
  "3規則1=每次申請事前審查之療程以18週為限"
  and "3規則2=使用總療程以36週為上限"
  and "3規則3=本藥品不得與cetuximab, panitumumab併用"


//============================================
// 檢核結果用：必要資料存在判斷
//============================================

define "Bevacizumab申請資料存在":
  Reusable."HasMedicationPlanRecord"(CodeConcept.L01FG01)

define "化學療法併用資料存在":
  exists (
    [MedicationRequest] MR
    where exists (
      MR.medication.coding Cdg
      where Cdg in CodeConcept.NHIMedication
        and (
          Cdg.code in CodeConcept.L01BC02
          or Cdg.code in CodeConcept.L01CE02
          or Cdg.code in CodeConcept.L01XA03
          or Cdg.code in CodeConcept.V03AF03
        )
    )
  )

define "主要疾病ICD資料存在":
  exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where D.sequence = 1
            and exists (
              D.diagnosis.coding Cdg
                where Cdg in CodeConcept.ICD10CM2023
                  or Cdg in CodeConcept.ICD10CM2014
            )
      )
  )

define "影像或檢查報告資料存在":
  exists (
    [DiagnosticReport] Report
    where Report.effective is not null
      and exists (
        Report.code.coding Cdg
        where Cdg in CodeConcept.ICD10PCS2023Image
          or Cdg in CodeConcept.ICD10PCS2014Image
          or Cdg in CodeConcept.LOINC
      )
  )

define "癌症分期資料存在":
  Reusable."癌症分期資料存在"

define "用藥線別資料存在":
  Reusable."用藥線別資料存在"

define "療程期間資料存在":
  Reusable."HasMedicationPlanTiming"(CodeConcept.L01FG01)

define "合併禁用藥品資料存在":
  exists (
    [MedicationRequest] MR
    where Reusable."HasMedicationCode"(MR, CodeConcept.L01FG01)
      or Reusable."HasMedicationCode"(MR, CodeConcept.L01FE)
  )

define "續用客觀證據資料存在":
  exists (
    [DiagnosticReport] Report
    where Report.effective is not null
      and exists (
        Report.code.coding Cdg
        where (
          Cdg in CodeConcept.ICD10PCS2023Image
          or Cdg in CodeConcept.ICD10PCS2014Image
        )
        and Cdg.code in CodeConcept.ImageReportCode
      )
  )


//============================================
// 列出「符合」項目判斷式
define "必要資料皆存在":
  not (
    (
      Reusable."初次申請" and (
          not "Bevacizumab申請資料存在"
          or not "化學療法併用資料存在"
          or not "主要疾病ICD資料存在"
          or not "影像或檢查報告資料存在"
          or not "癌症分期資料存在"
          or not "用藥線別資料存在"
        )
    )
    or (
      Reusable."續用申請" and (
          not "Bevacizumab申請資料存在"
          or not "續用客觀證據資料存在"
        )
    )
    or ((not "療程期間資料存在"))
  )


//============================================

define function "符合項目"():
  // 主要規定一：初次使用條件
  (if Reusable."初次申請" and ("1規則1=化學療法合併使用" or Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" or "1規則2-2=三個月內有影像報告" or "1規則2-3=三個月內有檢查報告" or "1規則2-4=癌症分期分數或結果為M>=1" or "1規則2-5=用藥線別為第一線")
    then '<主要規定一：初次使用條件>\n' +
         (if "1規則1-1=Bevacizumab與FOLFIRI（Folinicacid/5-fluorouracil/irinotecan）併用" 
           then '● 規則1-1：Bevacizumab與FOLFIRI（Folinicacid/5-fluorouracil/irinotecan）併用（參考資訊）\n' else '') +
         (if "1規則1-2=Bevacizumab與FOLFOX（Folinicacid/5-fluorouracil/oxaliplatin）併用" 
           then '● 規則1-2：Bevacizumab與FOLFOX（Folinicacid/5-fluorouracil/oxaliplatin）併用（參考資訊）\n' else '') +
         (if "1規則1-3=Bevacizumab與5-fluorouracil/leucovorin的化學療法合併使用" 
           then '● 規則1-3：Bevacizumab與5-fluorouracil/leucovorin的化學療法合併使用（參考資訊）\n' else '') +
         (if Reusable."主要疾病之ICD-10使用C18、C19、C20、C21" 
           then '● 規則2-1：主要疾病之ICD-10代碼為C18、C19、C20、C21\n' else '') +
         (if "1規則2-2=三個月內有影像報告"
           then '● 規則2-2：三個月內有影像報告\n' else '') +
         (if "1規則2-3=三個月內有檢查報告"
           then '● 規則2-3：三個月內有檢查報告\n' else '') +
         (if "1規則2-4=癌症分期分數或結果為M>=1" 
           then '● 規則2-4：癌症分期為轉移性（M≥1）\n' else '') +
         (if "1規則2-5=用藥線別為第一線" 
           then '● 規則2-5：用藥線別為第一線\n' else '') +
         '\n'  
    else '') +
  
  // 主要規定二：續用條件
  (if Reusable."續用申請" and "2規則1=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用" 
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '● 續用規則1：提出客觀證據（如：影像學）證實無惡化\n' +
         '\n'  
    else '') +
  
  // 主要規定三：藥品使用規則
  (if "3規則1=每次申請事前審查之療程以18週為限" or "3規則2=使用總療程以36週為上限" or not "3規則3-1=使用cetuximab、panitumumab藥品" or "3規則3-2=本藥品未與cetuximab、panitumumab併用"
    then '<主要規定三：藥品使用規則>\n' +
         (if "3規則1=每次申請事前審查之療程以18週為限" 
           then '● 規則3-1：每次申請事前審查之療程以18週為限（參考資訊）\n' else '') +
         (if "3規則2=使用總療程以36週為上限" 
           then '● 規則3-2：使用總療程以36週為上限（參考資訊）\n' else '') +
         (if not "3規則3-1=使用cetuximab、panitumumab藥品" 
           then '● 規則3-3：未使用cetuximab、panitumumab藥品（參考資訊）\n' else '') +
         (if "3規則3-2=本藥品未與cetuximab、panitumumab併用" 
           then '● 規則3-4：本藥品未與cetuximab、panitumumab併用（參考資訊）\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 條件或代碼不符合
//============================================

define function "不符合項目_條件或代碼不符合"():
  // 主要規定一：初次使用條件 - 已提供資料但條件或代碼不符合
  (if Reusable."初次申請" and (
    ("化學療法併用資料存在" and not "1規則1=化學療法合併使用")
    or ("主要疾病ICD資料存在" and not Reusable."主要疾病之ICD-10使用C18、C19、C20、C21")
    or ("影像或檢查報告資料存在" and not ("1規則2-2=三個月內有影像報告" or "1規則2-3=三個月內有檢查報告"))
    or ("癌症分期資料存在" and not "1規則2-4=癌症分期分數或結果為M>=1")
    or ("用藥線別資料存在" and not "1規則2-5=用藥線別為第一線")
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "化學療法併用資料存在" and not "1規則1=化學療法合併使用"
           then '▲ 規則1：未符合Bevacizumab與指定化學療法併用或醫令類別條件（參考資訊）\n' else '') +
         (if "主要疾病ICD資料存在" and not Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"
           then '▲ 規則2-1：主要疾病之ICD代碼未使用C18、C19、C20、C21\n' else '') +
         (if "影像或檢查報告資料存在" and not ("1規則2-2=三個月內有影像報告" or "1規則2-3=三個月內有檢查報告")
           then '▲ 規則2-2/2-3：未符合三個月內且代碼正確之影像報告或檢查報告條件\n' else '') +
         (if "癌症分期資料存在" and not "1規則2-4=癌症分期分數或結果為M>=1"
           then '▲ 規則2-4：癌症分期分數或結果不為M>=1\n' else '') +
         (if "用藥線別資料存在" and not "1規則2-5=用藥線別為第一線"
           then '▲ 規則2-5：用藥線別不為第一線\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 已提供資料但條件不符
  (if Reusable."續用申請" and "續用客觀證據資料存在" and not "2規則1=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用"
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '▲ 續用規則1：未符合客觀證據（如：影像學）證實無惡化條件\n' +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 已提供資料但條件或代碼不符合
  (if (
    ("療程期間資料存在" and not "3規則1=每次申請事前審查之療程以18週為限")
    or ("療程期間資料存在" and not "3規則2=使用總療程以36週為上限")
    or ("合併禁用藥品資料存在" and not "3規則3=本藥品不得與cetuximab, panitumumab併用")
  )
    then '<主要規定三：藥品使用規則>\n' +
         (if "療程期間資料存在" and not "3規則1=每次申請事前審查之療程以18週為限"
           then '▲ 規則3-1：每次申請事前審查之療程超過18週上限（參考資訊）\n' else '') +
         (if "療程期間資料存在" and not "3規則2=使用總療程以36週為上限"
           then '▲ 規則3-2：使用總療程超過36週上限（參考資訊）\n' else '') +
         (if "合併禁用藥品資料存在" and not "3規則3=本藥品不得與cetuximab, panitumumab併用"
           then '▲ 規則3-3/3-4：因與 cetuximab 或 panitumumab 併用，故不符合本藥品之使用規則（參考資訊）\n' else '')
    else '')

//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  // 主要規定一：初次使用條件 - 必要資料未填寫
  (if Reusable."初次申請" and (
    not "Bevacizumab申請資料存在"
    or not "化學療法併用資料存在"
    or not "主要疾病ICD資料存在"
    or not "影像或檢查報告資料存在"
    or not "癌症分期資料存在"
    or not "用藥線別資料存在"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if not "Bevacizumab申請資料存在"
           then '▲ 1條件申請醫令：未提供Bevacizumab申請醫令資料\n' else '') +
         (if not "化學療法併用資料存在"
           then '▲ 規則1：未提供化學療法併用資料（需有 FOLFIRI、FOLFOX 或 5-FU／leucovorin 之處方）（參考資訊）\n' else '') +
         (if not "主要疾病ICD資料存在"
           then '▲ 規則2-1：未提供主要疾病ICD診斷資料\n' else '') +
         (if not "影像或檢查報告資料存在"
           then '▲ 規則2-2/2-3：未提供影像報告或檢查報告資料\n' else '') +
         (if not "癌症分期資料存在"
           then '▲ 規則2-4：未提供癌症分期分數或結果資料\n' else '') +
         (if not "用藥線別資料存在"
           then '▲ 規則2-5：未提供用藥線別資料\n' else '') +
         '\n'
    else '') +

  // 主要規定二：續用條件 - 必要資料未填寫
  (if Reusable."續用申請" and (
    not "Bevacizumab申請資料存在"
    or not "續用客觀證據資料存在"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if not "Bevacizumab申請資料存在" then '▲ 2條件申請醫令：未提供Bevacizumab申請醫令資料\n' else '') +
         (if not "續用客觀證據資料存在" then '▲ 續用規則1：未提供客觀證據（如：影像學）\n' else '') +
         '\n'
    else '') +

  // 主要規定三：藥品使用規則 - 必要資料未填寫
  (if (not "療程期間資料存在")
    then '<主要規定三：藥品使用規則>\n' +
         '▲ 規則3-1/3-2：未提供療程起迄日期資料（參考資訊）\n' +
         '\n'
    else '')

//============================================
// 審核結果
//============================================

define "大腸直腸癌Bevacizumab第一線治療申請結果_布林":
  case
    when Reusable."初次申請" then (
      "1規則2=轉移性直腸結腸癌病患之第一線治療" and
      Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"
    )
    when Reusable."續用申請" then (
      "2規則1=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用"
    )
    else false
  end


define "大腸直腸癌Bevacizumab第一線用藥申請結果":
  if (
    Reusable."初次申請" and 
    "1規則2=轉移性直腸結腸癌病患之第一線治療" and
    Reusable."主要疾病之ICD-10使用C18、C19、C20、C21"
  )
  then '✓通過：初次使用－大腸直腸癌 Bevacizumab 第一線用藥申請'
  else if (
    Reusable."續用申請" and
    "2規則1=再次申請必須提出客觀證據（如：影像學）證實無惡化，才可繼續使用"
  )
  then '✓通過：續用－大腸直腸癌 Bevacizumab 第一線用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－大腸直腸癌 Bevacizumab 第一線用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－大腸直腸癌 Bevacizumab 第一線用藥申請'
  else '✖不通過：無法判定申請類型－大腸直腸癌 Bevacizumab 第一線用藥申請'

//============================================
// 審核報告總結
//============================================

define "報告總結":
  '\n=== 大腸直腸癌之Bevacizumab(一線治療) 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "大腸直腸癌Bevacizumab第一線用藥申請結果" +
  '\n===============================================\n'
