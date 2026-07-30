//肺癌_Crizotinib給付規定
library LCCrizotinibRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

include LCCodeConcept version '1.0.0' called CodeConcept

include LCReusable version '1.0.0' called Reusable

context Patient



//============================================
// 主要規定一：初次使用條件
//============================================

// 本次申請紀錄（以最新一筆申請作為本次申請）
define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.L01ED01)

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

// 首次申請紀錄（開始使用申請藥物）
define "首次申請紀錄":
  First(
    [MedicationRequest] MR
      where Reusable."IsMedicationPlan"(MR, CodeConcept.L01ED01)
      sort by FHIRHelpers.ToDateTime((dosageInstruction[0].timing.repeat.bounds as Period).start)
  )

define "首次申請起始日期":
  Reusable."GetStartTime"("首次申請紀錄")

// 前次申請紀錄（本次申請之前最近一次的申請）
define "前次申請紀錄":
  Reusable."LatestMedicationPlanBefore"(CodeConcept.L01ED01, "本次申請起始日期")

define "前次申請起始日期":
  Reusable."GetStartTime"("前次申請紀錄")

define "前次申請給藥4週後日期":
  "前次申請起始日期" + 28 days

/*規則1*/
//條件1:晚期非小細胞肺癌

define "ICD代碼檢核_布林值": Reusable."ICD-10使用C34"


define "醫令類別為1_布林值": Reusable."醫令類別為1"

define "3個月內有影像檢查報告":
  Reusable."HasRecentImageReport"("本次申請起始日期", 90)


define "癌症分期分數或結果為M≠0":
  Reusable."癌症分期分數或結果為M≠0"



define "3個月內有檢查報告":
  Reusable."HasRecentMolecularReport"("本次申請起始日期", 90)



define "1規則1-1=晚期非小細胞肺癌":
  Reusable."ICD-10使用C34"
  and Reusable."醫令類別為1"
  and "癌症分期分數或結果為M≠0"
  and (
    (not "3個月內有影像檢查報告" and not "3個月內有檢查報告")
    or ("3個月內有影像檢查報告" and "3個月內有檢查報告")
  )


//條件2:ROS-1陽性
define "1規則1-2=ROS-1陽性":
  Reusable."HasTestObservationWithInterpretationAndValuePattern"(CodeConcept.ROS1, { 'POS' }, '(?i).*(\+|陽性|positive|突變|fusion).*')
  or Reusable."HasGeneInfoObservationWithInterpretationAndTextPattern"(CodeConcept.ROS1, { 'POS' }, '(?i).*(\+|陽性|positive|突變|fusion).*')

define "1規則1=單獨使用於ROS-1陽性之晚期非小細胞肺癌患者":
"1規則1-1=晚期非小細胞肺癌"
and "1規則1-2=ROS-1陽性"


/*規則2*/

//條件1:非小細胞肺癌之病理或細胞檢查
define "1規則2-1=非小細胞肺癌之病理或細胞檢查":
"3個月內有檢查報告"


//條件2:ROS-1突變檢測報告 同 "1規則1-2=ROS-1陽性"


define "1規則2=初次申請時需檢具確實患有非小細胞肺癌之病理或細胞檢查報告及ROS-1突變檢測報告，且需符合全民健康保險藥品給付規定之通則十二":
"1規則2-1=非小細胞肺癌之病理或細胞檢查"
and "1規則1-2=ROS-1陽性"


//主要規定一
define "主要規定一":
"本次申請紀錄" is not null
and "1規則1=單獨使用於ROS-1陽性之晚期非小細胞肺癌患者"
and "1規則2=初次申請時需檢具確實患有非小細胞肺癌之病理或細胞檢查報告及ROS-1突變檢測報告，且需符合全民健康保險藥品給付規定之通則十二"



//============================================
// 主要規定二：續用條件
//============================================

/*規則1*/
//條件1-1:給藥4週後，需追蹤胸部X 光或電腦斷層等影像檢查評估療效
define "2規則1-1=給藥4週後，需追蹤胸部X 光或電腦斷層等影像檢查評估療效":
  "前次申請紀錄" is not null
  and exists (
    [DiagnosticReport] Report
    where exists (
      Report.code.coding Cdg
      where (
        Cdg in CodeConcept.ICD10PCS2023Image
        or Cdg in CodeConcept.ICD10PCS2014Image
      )
      and Cdg.code in CodeConcept.AlectinibEfficacyAssessmentImageCodes
    )
    and Report.effective is not null
    and FHIRHelpers.ToDateTime(Report.effective) >= "前次申請給藥4週後日期"
    and FHIRHelpers.ToDateTime(Report.effective) <= "本次申請起始日期"
  )

//條件1-2:往後每4週做胸部X 光檢查
define "2規則1-2=往後每4週做胸部X 光檢查":
  exists (
    [DiagnosticReport] CurrentReport
    where exists (
      CurrentReport.code.coding CurrentCdg
      where (
        CurrentCdg in CodeConcept.ICD10PCS2023Image
        or CurrentCdg in CodeConcept.ICD10PCS2014Image
      )
      and CurrentCdg.code in CodeConcept.AlectinibChestXRayImageCodes
    )
    and CurrentReport.effective is not null
    and FHIRHelpers.ToDateTime(CurrentReport.effective) <= "本次申請起始日期"
    and exists (
      [DiagnosticReport] PreviousReport
      where exists (
        PreviousReport.code.coding PreviousCdg
        where (
          PreviousCdg in CodeConcept.ICD10PCS2023Image
          or PreviousCdg in CodeConcept.ICD10PCS2014Image
        )
        and PreviousCdg.code in CodeConcept.AlectinibEfficacyAssessmentImageCodes
      )
      and PreviousReport.effective is not null
      and FHIRHelpers.ToDateTime(PreviousReport.effective) < FHIRHelpers.ToDateTime(CurrentReport.effective)
      and FHIRHelpers.ToDateTime(CurrentReport.effective) >= FHIRHelpers.ToDateTime(PreviousReport.effective) + 28 days
    )
  )

//條件1-3:每3個月需追蹤其作為評估藥效的影像（如胸部X 光或電腦斷層）
define "2規則1-3=每3個月需追蹤其作為評估藥效的影像":
  "首次申請紀錄" is not null
  and exists (
    [DiagnosticReport] Report
    where exists (
      Report.code.coding Cdg
      where (
        Cdg in CodeConcept.ICD10PCS2023Image
        or Cdg in CodeConcept.ICD10PCS2014Image
      )
      and Cdg.code in CodeConcept.AlectinibEfficacyAssessmentImageCodes
    )
    and Report.effective is not null
    and FHIRHelpers.ToDateTime(Report.effective) >= "首次申請起始日期" + 90 days
    and FHIRHelpers.ToDateTime(Report.effective) <= "本次申請起始日期"
  )


//主要規定二
define "主要規定二":
"2規則1-1=給藥4週後，需追蹤胸部X 光或電腦斷層等影像檢查評估療效"
and "2規則1-2=往後每4週做胸部X 光檢查"
and "2規則1-3=每3個月需追蹤其作為評估藥效的影像"


//============================================
// 主要規定三：藥品使用規則
//============================================


/*規則1*/

define "3規則1=每次申請之療程以3個月為限":
  Reusable."HasMedicationPlanPeriodWithinDays"(CodeConcept.L01ED01, 90)

/*規則2*/
//Start 到 End 的使用期間有重疊到同一天，且該筆有 QD 劑量資料，才會被加總進每日劑量。
define "3規則2-1=每日劑量資料存在":
  exists (
    [MedicationRequest] MR
    where Reusable."IsMedicationPlan"(MR, CodeConcept.L01ED01)
      and Reusable."HasDailyDoseData"(MR)
  )

define "3規則2-2=每日最大劑量限500mg":
  Reusable."HasConcurrentDailyDoseAtMost"(CodeConcept.L01ED01, 500.0)

define "3規則2":
"3規則2-1=每日劑量資料存在" and "3規則2-2=每日最大劑量限500mg"


/*規則3*/
//條件1:用於ROS-1陽性之晚期非小細胞肺癌時
define "3規則3-1=用於ROS-1陽性之晚期非小細胞肺癌時":
"1規則1-1=晚期非小細胞肺癌"
and "1規則1-2=ROS-1陽性"


//條件2-1:與entrectinib 僅得擇一使用
define "3規則3-2-1=與entrectinib 僅得擇一使用":
  not Reusable."HasConcurrentMedicationUse"(
    CodeConcept.L01ED01,
    CodeConcept.L01EX14
  )

//條件2-2:發生嚴重不良反應或耐受不良，與entrectinib可互換
define "3規則3-2-2=發生嚴重不良反應或耐受不良，與entrectinib可互換":
  "本次申請起始日期" is not null
  and exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(MR, CodeConcept.L01EX14)
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetEndTime"(MR) < "本次申請起始日期"
        and exists (
          [Claim] C
            where exists (
              C.diagnosis D
                where First(D."type").text is not null
                  and Matches(First(D."type").text, '(?i).*無法忍受entrectinib副作用.*')
            )
        )
  )

define "3規則3-2=與entrectinib 僅得擇一使用或發生嚴重不良反應/耐受不良可互換":
"3規則3-2-1=與entrectinib 僅得擇一使用"
or "3規則3-2-2=發生嚴重不良反應或耐受不良，與entrectinib可互換"

define "3規則3-ROS1=用於ROS-1陽性之晚期非小細胞肺癌時，與entrectinib 僅得擇一使用或發生嚴重不良反應/耐受不良可互換":
"3規則3-1=用於ROS-1陽性之晚期非小細胞肺癌時"
and "3規則3-2=與entrectinib 僅得擇一使用或發生嚴重不良反應/耐受不良可互換"


//條件3:用於ALK 陽性之晚期非小細胞肺癌第一線治療時
define "3規則3-3=用於ALK 陽性之晚期非小細胞肺癌第一線治療時":
"1規則1-1=晚期非小細胞肺癌"
and (
  Reusable."HasTestObservationWithInterpretationAndValuePattern"(CodeConcept.ALK, { 'POS' }, '(?i).*(\+|陽性|positive|Positive).*')
  or Reusable."HasGeneInfoObservationWithInterpretationAndTextPattern"(CodeConcept.ALK, { 'POS' }, '(?i).*(\+|陽性|positive|Positive).*')
)
and Reusable."用藥線別=1"

//條件4-1:與ceritinib、alectinib、brigatinib、lorlatinib僅得擇一使用
define "3規則3-4-1=與ceritinib、alectinib、brigatinib、lorlatinib僅得擇一使用":
  not Reusable."HasConcurrentMedicationUse"(
    CodeConcept.L01ED01,
    CodeConcept.L01ED02 union CodeConcept.L01ED03 union CodeConcept.L01ED04 union CodeConcept.L01ED05
  )

//條件4-2:發生嚴重不良反應或耐受不良，與ceritinib、alectinib、brigatinib、lorlatinib可互換
define "3規則3-4-2=發生嚴重不良反應或耐受不良，與ceritinib、alectinib、brigatinib、lorlatinib可互換":
  "本次申請起始日期" is not null
  and exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(
        MR,
        CodeConcept.L01ED02 union CodeConcept.L01ED03 union CodeConcept.L01ED04 union CodeConcept.L01ED05
      )
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetEndTime"(MR) < "本次申請起始日期"
  )
  and exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where First(D."type").text is not null
            and Matches(First(D."type").text, '(?i).*無法忍受ceritinib、alectinib、brigatinib、lorlatinib副作用.*')
      )
  )

define "3規則3-4=與ceritinib、alectinib、brigatinib、lorlatinib僅得擇一使用或發生嚴重不良反應/耐受不良可互換":
"3規則3-4-1=與ceritinib、alectinib、brigatinib、lorlatinib僅得擇一使用"
or "3規則3-4-2=發生嚴重不良反應或耐受不良，與ceritinib、alectinib、brigatinib、lorlatinib可互換"

define "3規則3-ALK=Crizotinib 與ceritinib、alectinib、brigatinib、lorlatinib 用於ALK 陽性之晚期非小細胞肺癌第一線治療時，僅得擇一使用，除因病人使用後，發生嚴重不良反應或耐受不良之情形外，不得互換":
"3規則3-3=用於ALK 陽性之晚期非小細胞肺癌第一線治療時"
and "3規則3-4=與ceritinib、alectinib、brigatinib、lorlatinib僅得擇一使用或發生嚴重不良反應/耐受不良可互換"

define "3規則3=用於ROS-1陽性或ALK陽性之晚期非小細胞肺癌時，與相關標靶藥物僅得擇一使用或發生嚴重不良反應/耐受不良可互換":
"3規則3-ROS1=用於ROS-1陽性之晚期非小細胞肺癌時，與entrectinib 僅得擇一使用或發生嚴重不良反應/耐受不良可互換"
or "3規則3-ALK=Crizotinib 與ceritinib、alectinib、brigatinib、lorlatinib 用於ALK 陽性之晚期非小細胞肺癌第一線治療時，僅得擇一使用，除因病人使用後，發生嚴重不良反應或耐受不良之情形外，不得互換"

//主要規定三
define "主要規定三":
"3規則1=每次申請之療程以3個月為限"
and "3規則2"
and "3規則3=用於ROS-1陽性或ALK陽性之晚期非小細胞肺癌時，與相關標靶藥物僅得擇一使用或發生嚴重不良反應/耐受不良可互換"


define "主要規定三_核心條件":
  "3規則2" and "3規則3=用於ROS-1陽性或ALK陽性之晚期非小細胞肺癌時，與相關標靶藥物僅得擇一使用或發生嚴重不良反應/耐受不良可互換"

//============================================
// 檢核結果用：必要資料存在判斷
//============================================

define "主要疾病ICD資料存在":
  exists (
    [Claim] C
      where exists (
        (C.diagnosis) D
          where D.sequence = 1
            and exists (
              D.diagnosis.coding Cdg
                where Cdg in CodeConcept.ICD10CM2023
                  or Cdg in CodeConcept.ICD10CM2014
            )
      )
  )

define "癌症分期資料存在":
  exists (
    [Observation] O
      where exists (
        O.code.coding Cdg
          where Cdg.code = '399390009'
            and Cdg in CodeConcept.SNOMED
      )
      and O.value is not null
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

define "1規則1-1=影像或檢查報告資料存在":
  "影像或檢查報告資料存在"

define "1規則2-1=檢查報告資料存在":
  exists (
    [DiagnosticReport] Report
    where Report.effective is not null
      and exists (
        Report.code.coding Cdg
        where Cdg in CodeConcept.LOINC
          and Cdg.code in CodeConcept.MolecularReport
      )
  )

define "1規則1-2=ROS1檢測資料存在":
  exists (
    [Observation] OBs
      where Reusable."IsTestObservation"(OBs)
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept.ROS1
        )
        and (
          OBs.value is not null
          or exists (OBs.interpretation I where I is not null)
        )
  )
  or exists (
    [Observation] OBs
      where Reusable."IsGeneInfoObservation"(OBs)
        and Reusable."IsGenePanelObservation"(OBs)
        and exists (
          OBs.component Comp
            where exists (
              Comp.code.coding Cdg
                where Cdg in CodeConcept.LOINC
                  and Cdg.code in CodeConcept.ROS1
            )
            and Comp.value is not null
        )
  )

define "ALK檢測資料存在":
  exists (
    [Observation] OBs
      where Reusable."IsTestObservation"(OBs)
        and exists (
          OBs.code.coding Cdg
            where Cdg in CodeConcept.LOINC
              and Cdg.code in CodeConcept.ALK
        )
        and (
          OBs.value is not null
          or exists (OBs.interpretation I where I is not null)
        )
  )
  or exists (
    [Observation] OBs
      where Reusable."IsGeneInfoObservation"(OBs)
        and Reusable."IsGenePanelObservation"(OBs)
        and exists (
          OBs.component Comp
            where exists (
              Comp.code.coding Cdg
                where Cdg in CodeConcept.LOINC
                  and Cdg.code in CodeConcept.ALK
            )
            and Comp.value is not null
        )
  )

define "3規則3-3=ALK檢測資料存在":
  "ALK檢測資料存在"

define "用藥線別資料存在":
  exists (
    [Claim] C
      where exists (
        C.item I
          where exists (
            I.modifier M
              where exists (
                M.coding Cdg
                  where Cdg in CodeConcept.NHILOT
              )
          )
      )
  )

define "3規則3-3=用藥線別資料存在":
  "用藥線別資料存在"

define "2規則1-1=療效評估影像資料存在":
  "前次申請紀錄" is not null
  and exists (
    [DiagnosticReport] Report
    where Report.effective is not null
      and exists (
        Report.code.coding Cdg
        where (
          Cdg in CodeConcept.ICD10PCS2023Image
          or Cdg in CodeConcept.ICD10PCS2014Image
        )
        and Cdg.code in CodeConcept.AlectinibEfficacyAssessmentImageCodes
      )
  )

define "2規則1-2=胸部X光資料存在":
  exists (
    [DiagnosticReport] Report
    where Report.effective is not null
      and exists (
        Report.code.coding Cdg
        where (
          Cdg in CodeConcept.ICD10PCS2023Image
          or Cdg in CodeConcept.ICD10PCS2014Image
        )
        and Cdg.code in CodeConcept.AlectinibChestXRayImageCodes
      )
  )

define "2規則1-3=三個月追蹤影像資料存在":
  "首次申請紀錄" is not null
  and exists (
    [DiagnosticReport] Report
    where Report.effective is not null
      and exists (
        Report.code.coding Cdg
        where (
          Cdg in CodeConcept.ICD10PCS2023Image
          or Cdg in CodeConcept.ICD10PCS2014Image
        )
        and Cdg.code in CodeConcept.AlectinibEfficacyAssessmentImageCodes
      )
  )

define "3規則1=療程期間資料存在":
  exists (
    [MedicationRequest] MR
    where Reusable."IsMedicationPlan"(MR, CodeConcept.L01ED01)
  )

define "3規則3-2-2=不良反應或耐受不良資料存在":
  exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where First(D."type").text is not null
      )
  )


define "必要資料皆存在":
  not (
    (
      Reusable."初次申請" and (
          "本次申請紀錄" is null
          or not "主要疾病ICD資料存在"
          or not "癌症分期資料存在"
          or not "1規則1-1=影像或檢查報告資料存在"
          or not "1規則2-1=檢查報告資料存在"
          or not "1規則1-2=ROS1檢測資料存在"
        )
    )
    or (
      Reusable."續用申請" and (
          "本次申請紀錄" is null
          or "前次申請紀錄" is null
          or not "2規則1-1=療效評估影像資料存在"
          or not "2規則1-2=胸部X光資料存在"
          or not "2規則1-3=三個月追蹤影像資料存在"
        )
    )
    or (
      (
          not "3規則1=療程期間資料存在"
          or not "3規則2-1=每日劑量資料存在"
        )
    )
  )


//============================================
// 列出「符合」項目判斷式
//============================================

define function "符合項目"():
  (if Reusable."初次申請" and "主要規定一"
    then '<主要規定一：初次使用條件>\n' +
         '● 1規則1：單獨使用於ROS-1陽性之晚期非小細胞肺癌患者\n' +
         '  ● 1規則1-1：晚期非小細胞肺癌\n' +
         '  ● 1規則1-2：ROS-1陽性\n' +
         '● 1規則2：初次申請時需檢具病理或細胞檢查報告及ROS-1突變檢測報告\n' +
         '  ● 1規則2-1：非小細胞肺癌之病理或細胞檢查\n' +
         '  ● 1規則2-2：ROS-1突變檢測報告\n\n'
    else if Reusable."初次申請" and (
      "1規則1-1=晚期非小細胞肺癌"
      or "1規則1-2=ROS-1陽性"
      or "1規則2-1=非小細胞肺癌之病理或細胞檢查"
    )
      then '<主要規定一：初次使用條件>\n' +
           (if "1規則1-1=晚期非小細胞肺癌" then '● 1規則1-1：晚期非小細胞肺癌\n' else '') +
           (if "1規則1-2=ROS-1陽性" then '● 1規則1-2：ROS-1陽性\n' else '') +
           (if "1規則2-1=非小細胞肺癌之病理或細胞檢查" then '● 1規則2-1：非小細胞肺癌之病理或細胞檢查\n' else '') +
           '\n'
      else '') +

  (if Reusable."續用申請" and "主要規定二"
    then '<主要規定二：續用條件>\n' +
         '● 2規則1：續用追蹤影像檢查評估療效\n' +
         '  ● 2規則1-1：給藥4週後追蹤胸部X光或電腦斷層等影像檢查\n' +
         '  ● 2規則1-2：往後每4週做胸部X光檢查\n' +
         '  ● 2規則1-3：每3個月追蹤作為評估藥效的影像\n\n'
    else if Reusable."續用申請" and (
      "2規則1-1=給藥4週後，需追蹤胸部X 光或電腦斷層等影像檢查評估療效"
      or "2規則1-2=往後每4週做胸部X 光檢查"
      or "2規則1-3=每3個月需追蹤其作為評估藥效的影像"
    )
      then '<主要規定二：續用條件>\n' +
           (if "2規則1-1=給藥4週後，需追蹤胸部X 光或電腦斷層等影像檢查評估療效" then '● 2規則1-1：給藥4週後追蹤胸部X光或電腦斷層等影像檢查\n' else '') +
           (if "2規則1-2=往後每4週做胸部X 光檢查" then '● 2規則1-2：往後每4週做胸部X光檢查\n' else '') +
           (if "2規則1-3=每3個月需追蹤其作為評估藥效的影像" then '● 2規則1-3：每3個月追蹤作為評估藥效的影像\n' else '') +
           '\n'
      else '') +

  (if "主要規定三"
    then '<主要規定三：藥品使用規則>\n' +
         '● 3規則1：每次申請之療程以3個月為限（參考資訊）\n' +
         '● 3規則2：每日最大劑量限500mg\n' +
         '  ● 3規則2-1：每日劑量資料存在\n' +
         '  ● 3規則2-2：每日最大劑量限500mg\n' +
         '● 3規則3：用於ROS-1陽性或ALK陽性之晚期非小細胞肺癌時，與相關標靶藥物僅得擇一使用或因嚴重不良反應/耐受不良可互換\n\n'
    else if "3規則1=每次申請之療程以3個月為限" or "3規則2" or "3規則3=用於ROS-1陽性或ALK陽性之晚期非小細胞肺癌時，與相關標靶藥物僅得擇一使用或發生嚴重不良反應/耐受不良可互換"
      then '<主要規定三：藥品使用規則>\n' +
           (if "3規則1=每次申請之療程以3個月為限" then '● 3規則1：每次申請之療程以3個月為限（參考資訊）\n' else '') +
           (if "3規則2" then '● 3規則2：每日最大劑量限500mg\n' else '') +
           (if "3規則3=用於ROS-1陽性或ALK陽性之晚期非小細胞肺癌時，與相關標靶藥物僅得擇一使用或發生嚴重不良反應/耐受不良可互換" then '● 3規則3：ROS-1/ALK相關標靶藥物擇一使用或可互換條件\n' else '') +
           '\n'
      else '')


//============================================
// 列出「不符合」項目判斷式 - 條件或代碼不符合
//============================================

define function "不符合項目_條件或代碼不符合"():
  (if Reusable."初次申請" and not "主要規定一" and (
    ("主要疾病ICD資料存在" and not Reusable."ICD-10使用C34")
    or ("癌症分期資料存在" and not "癌症分期分數或結果為M≠0")
    or ("1規則1-1=影像或檢查報告資料存在" and not "1規則1-1=晚期非小細胞肺癌")
    or ("1規則2-1=檢查報告資料存在" and not "1規則2-1=非小細胞肺癌之病理或細胞檢查")
    or ("1規則1-2=ROS1檢測資料存在" and not "1規則1-2=ROS-1陽性")
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "主要疾病ICD資料存在" and not Reusable."ICD-10使用C34" then '▲ 1條件ICD代碼檢核：未符合主要疾病ICD代碼C34條件\n' else '') +
         (if "癌症分期資料存在" and not "癌症分期分數或結果為M≠0" then '▲ 1規則1-1：未符合癌症分期分數或結果M≠0條件\n' else '') +
         (if "1規則1-1=影像或檢查報告資料存在" and not "1規則1-1=晚期非小細胞肺癌" then '▲ 1規則1-1：未符合晚期非小細胞肺癌條件\n' else '') +
         (if "1規則2-1=檢查報告資料存在" and not "1規則2-1=非小細胞肺癌之病理或細胞檢查" then '▲ 1規則2-1：未符合「三個月內且代碼正確」之病理或細胞檢查報告條件\n' else '') +
         (if "1規則1-2=ROS1檢測資料存在" and not "1規則1-2=ROS-1陽性" then '▲ 1規則1-2：未符合ROS-1陽性或突變條件\n' else '') +
         '\n'
    else '') +

  (if Reusable."續用申請" and (
    ("2規則1-1=療效評估影像資料存在" and not "2規則1-1=給藥4週後，需追蹤胸部X 光或電腦斷層等影像檢查評估療效")
    or ("2規則1-2=胸部X光資料存在" and not "2規則1-2=往後每4週做胸部X 光檢查")
    or ("2規則1-3=三個月追蹤影像資料存在" and not "2規則1-3=每3個月需追蹤其作為評估藥效的影像")
  )
    then '<主要規定二：續用條件>\n' +
         (if "2規則1-1=療效評估影像資料存在" and not "2規則1-1=給藥4週後，需追蹤胸部X 光或電腦斷層等影像檢查評估療效" then '▲ 2規則1-1：未符合給藥4週後影像檢查評估療效條件\n' else '') +
         (if "2規則1-2=胸部X光資料存在" and not "2規則1-2=往後每4週做胸部X 光檢查" then '▲ 2規則1-2：未符合前一次影像檢查後4週之胸部X光檢查條件\n' else '') +
         (if "2規則1-3=三個月追蹤影像資料存在" and not "2規則1-3=每3個月需追蹤其作為評估藥效的影像" then '▲ 2規則1-3：未符合開始使用申請藥物後每3個月追蹤影像條件\n' else '') +
         '\n'
    else '') +

  (if (
    ("3規則1=療程期間資料存在" and not "3規則1=每次申請之療程以3個月為限")
    or ("3規則2-1=每日劑量資料存在" and not "3規則2-2=每日最大劑量限500mg")
    or (not "3規則3=用於ROS-1陽性或ALK陽性之晚期非小細胞肺癌時，與相關標靶藥物僅得擇一使用或發生嚴重不良反應/耐受不良可互換")
  )
    then '<主要規定三：藥品使用規則>\n' +
         (if "3規則1=療程期間資料存在" and not "3規則1=每次申請之療程以3個月為限" then '▲ 3規則1：未符合每次申請之療程以3個月為限條件（參考資訊）\n' else '') +
         (if "3規則2-1=每日劑量資料存在" and not "3規則2-2=每日最大劑量限500mg" then '▲ 3規則2：未符合每日最大劑量限500mg條件\n' else '') +
         (if not "3規則3=用於ROS-1陽性或ALK陽性之晚期非小細胞肺癌時，與相關標靶藥物僅得擇一使用或發生嚴重不良反應/耐受不良可互換" then '▲ 3規則3：未符合ROS-1/ALK用藥或相關標靶藥物擇一使用/可互換條件\n' else '') +
         '\n'
    else '')


//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  (if Reusable."初次申請" and (
    "本次申請紀錄" is null
    or not "主要疾病ICD資料存在"
    or not "癌症分期資料存在"
    or not "1規則1-1=影像或檢查報告資料存在"
    or not "1規則2-1=檢查報告資料存在"
    or not "1規則1-2=ROS1檢測資料存在"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "本次申請紀錄" is null then '▲ 1條件申請醫令：未提供Crizotinib申請醫令資料\n' else '') +
         (if not "主要疾病ICD資料存在" then '▲ 1條件ICD代碼檢核：未提供主要疾病ICD診斷資料\n' else '') +
         (if not "癌症分期資料存在" then '▲ 1規則1-1：未提供癌症分期分數或結果資料\n' else '') +
         (if not "1規則1-1=影像或檢查報告資料存在" then '▲ 1規則1-1：未提供影像報告或檢查報告資料\n' else '') +
         (if not "1規則2-1=檢查報告資料存在" then '▲ 1規則2-1：未提供病理或細胞檢查報告資料\n' else '') +
         (if not "1規則1-2=ROS1檢測資料存在" then '▲ 1規則1-2：未提供ROS-1檢測資料\n' else '') +
         '\n'
    else '') +

  (if Reusable."續用申請" and (
    "本次申請紀錄" is null
    or "前次申請紀錄" is null
    or not "2規則1-1=療效評估影像資料存在"
    or not "2規則1-2=胸部X光資料存在"
    or not "2規則1-3=三個月追蹤影像資料存在"
  )
    then '<主要規定二：續用條件>\n' +
         (if "本次申請紀錄" is null then '▲ 2條件申請醫令：未提供本次Crizotinib申請醫令資料\n' else '') +
         (if "前次申請紀錄" is null then '▲ 2條件前次申請：未提供前次Crizotinib申請資料\n' else '') +
         (if not "2規則1-1=療效評估影像資料存在" then '▲ 2規則1-1：未提供療效評估影像資料\n' else '') +
         (if not "2規則1-2=胸部X光資料存在" then '▲ 2規則1-2：未提供胸部X光檢查資料\n' else '') +
         (if not "2規則1-3=三個月追蹤影像資料存在" then '▲ 2規則1-3：未提供評估藥效之追蹤影像資料\n' else '') +
         '\n'
    else '') +

  (if (
    not "3規則1=療程期間資料存在"
    or not "3規則2-1=每日劑量資料存在"
  )
    then '<主要規定三：藥品使用規則>\n' +
         (if not "3規則1=療程期間資料存在" then '▲ 3規則1：未提供療程起迄日期資料（參考資訊）\n' else '') +
         (if not "3規則2-1=每日劑量資料存在" then '▲ 3規則2：未提供每日劑量資料\n' else '') +
         '\n'
    else '')


//============================================
// 審核結果
//============================================

define "肺癌Crizotinib申請結果_布林":
  case
    when Reusable."初次申請" then (
      "主要規定一"
      and "主要規定三_核心條件"
    )
    when Reusable."續用申請" then (
      "主要規定二"
      and "主要規定三_核心條件"
    )
    else false
  end

define "肺癌Crizotinib申請結果":
  if Reusable."初次申請" and "主要規定一" and "主要規定三_核心條件"
  then '✓通過：初次使用－肺癌 Crizotinib 用藥申請'
  else if Reusable."續用申請" and "主要規定二" and "主要規定三_核心條件"
  then '✓通過：續用－肺癌 Crizotinib 用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－肺癌 Crizotinib 用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－肺癌 Crizotinib 用藥申請'
  else '✖不通過：無法判定申請類型－肺癌 Crizotinib 用藥申請'


//============================================
// 報告總結
//============================================

define "報告總結":
  '\n=== 肺癌之 Crizotinib 申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "肺癌Crizotinib申請結果"+
  '\n===============================================\n'
