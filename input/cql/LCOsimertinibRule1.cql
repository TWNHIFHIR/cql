//肺癌_Osimertinib給付規定(肺腺癌之第一線治療)
library LCOsimertinibRule1 version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers
include LCCodeConcept version '1.0.0' called CodeConcept
include LCReusable version '1.0.0' called Reusable

context Patient

//============================================
// 申請紀錄
//============================================

define "本次申請紀錄":
  Reusable."LatestMedicationPlan"(CodeConcept.L01EB04)

define "本次申請起始日期":
  Reusable."GetStartTime"("本次申請紀錄")

define "3個月內有影像檢查報告":
  Reusable."HasRecentImageReport"("本次申請起始日期", 90)

define "3個月內有檢查報告":
  Reusable."HasRecentMolecularReport"("本次申請起始日期", 90)

define "3個月內有檢查報告(部分1)":
  Reusable."HasRecentMolecularReport1"("本次申請起始日期", 90)

define "3個月內有檢查報告(部分2)":
  Reusable."HasRecentMolecularReport2"("本次申請起始日期", 90)

define "癌症分期分數或結果為M≠0":
  Reusable."癌症分期分數或結果為M≠0"

define "癌症分期分數或結果為T>=3":
  Reusable."癌症分期分數或結果為T>=3"

define "癌症分期分數或結果為N>=2":
  Reusable."癌症分期分數或結果為N>=2"



//============================================
// 主要規定一：初次使用條件
//============================================

/*規則1*/
define "1規則1-1-1=EGFR Exon 19 Del基因突變":
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
          where ComponentCodeCoding.code in CodeConcept.EGFRExon19Del
        )
      )
      and RasO.value is not null
      and RasO.value is FHIR.string
      and Matches((RasO.value as FHIR.string).value, '(?i).*(mutation|變異|突變).*(positive|陽性).*')
  )

  define "1規則1-1-2=Exon 21 L858R基因突變":
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
            where ComponentCodeCoding.code in CodeConcept.Exon21L858R
            )
        )
        and RasO.value is not null
        and RasO.value is FHIR.string
        and Matches((RasO.value as FHIR.string).value, '(?i).*(mutation|變異|突變).*(positive|陽性).*')
    )

  define "1規則1-1=具有EGFR Exon 19 Del或Exon 21 L858R基因突變":
    "1規則1-1-1=EGFR Exon 19 Del基因突變"
    or "1規則1-1-2=Exon 21 L858R基因突變"

  define "1規則1-2-1=局部侵犯性":
    Reusable."HasClaimDiagnosisText"('(?i).*病摘提及具有局部侵犯性.*')

  define "1規則1-2-2=轉移性(即為IIIB、IIIC期或第Ⅳ期)":
    "3個月內有影像檢查報告"
    and (
        ("癌症分期分數或結果為T>=3" and "癌症分期分數或結果為N>=2") 
        or "癌症分期分數或結果為M≠0"
      )
    
  define "1規則1-2=局部侵犯性或轉移性":
    "1規則1-2-1=局部侵犯性"
    or "1規則1-2-2=轉移性(即為IIIB、IIIC期或第Ⅳ期)"

  define "1規則1-3=肺腺癌病患之第一線治療":
    Reusable."ICD-10使用C34"
    and Reusable."HasClaimDiagnosisText"('(?i).*(Adenocarcinom|肺腺癌).*')
    and (
        (not "3個月內有影像檢查報告" and not "3個月內有檢查報告")
        or ("3個月內有影像檢查報告" and "3個月內有檢查報告")
    )
    and Reusable."HasReportResultString"('(?i).*(Adenocarcinom|肺腺癌).*')
    and Reusable."用藥線別=1"
    and Reusable."續用註記為1"
    and Reusable."醫令類別為1"

  define "1規則1=具有EGFR Exon 19 Del或Exon 21 L858R基因突變之局部侵犯性或轉移性":
    "1規則1-1=具有EGFR Exon 19 Del或Exon 21 L858R基因突變"
    and "1規則1-2=局部侵犯性或轉移性"
    and "1規則1-3=肺腺癌病患之第一線治療"

  /*規則2*/
  define "1規則2-1-1=初次申請時需檢具確實患有肺腺癌之病理報告":
    "3個月內有檢查報告(部分1)"
    and Reusable."HasReportResultString"('(?i).*(Adenocarcinom|肺腺癌).*')
    and exists (
      [DiagnosticReport] DR
        where exists (
          DR.presentedForm P
            where P.url is not null
        )
    )

  define "1規則2-1-2=初次申請時需檢具確實患有肺腺癌之細胞檢查報告":
    "3個月內有檢查報告(部分2)"
    and Reusable."HasReportResultString"('(?i).*(Adenocarcinom|肺腺癌).*')
    and exists (
      [DiagnosticReport] DR
        where exists (
          DR.presentedForm P
            where P.url is not null
        )
    )

  define "1規則2-1=初次申請時需檢具確實患有肺腺癌之病理或細胞檢查報告":
    "1規則2-1-1=初次申請時需檢具確實患有肺腺癌之病理報告"
    or "1規則2-1-2=初次申請時需檢具確實患有肺腺癌之細胞檢查報告"

  define "1規則2-2=檢附EGFR基因檢測結果報告":
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
          where ComponentCodeCoding.code in CodeConcept.EGFRExon
        )
      )
      and RasO.value is not null
      and RasO.value is FHIR.string
      and Matches((RasO.value as FHIR.string).value, '(?i).*(mutation|變異|突變).*(positive|陽性).*')
  )

  define "1規則2=初次申請時需檢具確實患有肺腺癌或非小細胞肺癌之病理或細胞檢查報告":
  "1規則2-1=初次申請時需檢具確實患有肺腺癌之病理或細胞檢查報告"
  and "1規則2-2=檢附EGFR基因檢測結果報告"

  define "主要規定一":
  "本次申請紀錄" is not null
  and "1規則1=具有EGFR Exon 19 Del或Exon 21 L858R基因突變之局部侵犯性或轉移性"
  and "1規則2=初次申請時需檢具確實患有肺腺癌或非小細胞肺癌之病理或細胞檢查報告"

//============================================
// 主要規定二：續用條件－治療持續給付
//============================================

/*規則1*/
define "2規則1=再次申請時需附上治療後相關臨床資料":
"3個月內有影像檢查報告"
and Reusable."續用註記為2"
and Reusable."醫令類別為1"

/*規則2*/
define "2規則2-1=每次處方以4週為限":
Reusable."HasMedicationPlanPeriodWithinDays"(CodeConcept.L01EB04, 28)

// 與「2規則2-3=每8至12週需進行完整療效評估(如胸部X光或電腦斷層)」同邏輯
define "2規則2-2=給藥4週後需追蹤胸部X光或電腦斷層等影像檢查評估療效":
exists (
    [DiagnosticReport] Report
      where exists (
        Report.code.coding ReportCdg
        where (
          ReportCdg in CodeConcept.ICD10PCS2023Image
          or ReportCdg in CodeConcept.ICD10PCS2014Image
        )
        and ReportCdg.code in CodeConcept.AlectinibEfficacyAssessmentImageCodes
      )
  )

define "2規則2":
"2規則2-1=每次處方以4週為限"
and "2規則2-2=給藥4週後需追蹤胸部X光或電腦斷層等影像檢查評估療效"

define "主要規定二":
"本次申請紀錄" is not null
and "2規則1=再次申請時需附上治療後相關臨床資料"
and "2規則2"

//============================================
// 主要規定三：藥品使用規則
//============================================

/*規則1*/
define "3規則1=每次申請事前審查之療程以三個月為限":
Reusable."HasMedicationPlanPeriodWithinDays"(CodeConcept.L01EB04, 84)
and Reusable."醫令類別為1"

/*規則3*/
define "3規則3-1-1=僅得擇一使用":
  not Reusable."HasConcurrentMedicationUse"(
    CodeConcept.L01EB04,
    CodeConcept.L01EB01 union CodeConcept.L01EB02 union CodeConcept.L01EB03 union CodeConcept.L01EB07
  )

define "3規則3-1-2=除因耐受性不良不得互換":
"本次申請起始日期" is not null
  and exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(
        MR,
        CodeConcept.L01EB01 union CodeConcept.L01EB02 union CodeConcept.L01EB03 union CodeConcept.L01EB07
      )
        and Reusable."HasValidTiming"(MR)
        and Reusable."GetEndTime"(MR) < "本次申請起始日期"
  )
  and Reusable."HasReportResultString"('(?i).*使用L01EB01, L01EB02, L01EB03, L01EB07有耐受性不良.*')

define "3規則3-1=與gefitinib、erlotinib、afatinib及dacomitinib僅得擇一使用，除因耐受性不良不得互換":
"3規則3-1-1=僅得擇一使用"
and "3規則3-1-2=除因耐受性不良不得互換"

define "3規則3-2-1-1=EGFR Exon 19 Del基因突變":
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
          where ComponentCodeCoding.code in CodeConcept.EGFRExon19Del
        )
      )
      and RasO.value is not null
      and RasO.value is FHIR.string
      and Matches((RasO.value as FHIR.string).value, '(?i).*(mutation|變異|突變).*(positive|陽性).*')
  )

define "3規則3-2-1-2=Exon 21 L858R基因突變":
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
            where ComponentCodeCoding.code in CodeConcept.Exon21L858R
            )
        )
        and RasO.value is not null
        and RasO.value is FHIR.string
        and Matches((RasO.value as FHIR.string).value, '(?i).*(mutation|變異|突變).*(positive|陽性).*')
    )

define "3規則3-2-1=限單獨使用於具有EGFR Exon 19 Del或Exon 21 L858R基因突變":
    "3規則3-2-1-1=EGFR Exon 19 Del基因突變"
    or "3規則3-2-1-2=Exon 21 L858R基因突變"

define "3規則3-2-2-1=局部侵犯性":
Reusable."HasReportResultString"('(?i).*(具有局部侵犯性).*')

define "3規則3-2-2-2=轉移性":
  "3個月內有影像檢查報告"
    and (
        ("癌症分期分數或結果為T>=3" and "癌症分期分數或結果為N>=2") 
        or "癌症分期分數或結果為M≠0"
      )

define "3規則3-2-2=局部侵犯性或轉移性":
  "3規則3-2-2-1=局部侵犯性"
    or "3規則3-2-2-2=轉移性"

define "3規則3-2-3=肺腺癌病患":
  Reusable."ICD-10使用C34"
    and Reusable."HasClaimDiagnosisText"('(?i).*(Adenocarcinom|肺腺癌).*')
    and "3個月內有檢查報告"
    and Reusable."HasReportResultString"('(?i).*(Adenocarcinom|肺腺癌).*')

define "3規則3-2=如需更換藥品，須符合具有局部侵犯性或轉移性肺腺癌病患":
"3規則3-2-1=限單獨使用於具有EGFR Exon 19 Del或Exon 21 L858R基因突變"
and "3規則3-2-2=局部侵犯性或轉移性"
and "3規則3-2-3=肺腺癌病患"

define "3規則3":
"3規則3-1=與gefitinib、erlotinib、afatinib及dacomitinib僅得擇一使用，除因耐受性不良不得互換"
and "3規則3-2=如需更換藥品，須符合具有局部侵犯性或轉移性肺腺癌病患"

/*規則4*/
define "3規則4=每日限用1粒":
Reusable."HasConcurrentDailyDoseAtMost"(CodeConcept.L01EB04, 1, '{tbl}', 'QD')

define "主要規定三":
"3規則1=每次申請事前審查之療程以三個月為限"
and "3規則3"
and "3規則4=每日限用1粒"

define "主要規定三_核心條件":
  "3規則3" and "3規則4=每日限用1粒"

//============================================
// 檢核結果用：必要資料存在判斷
//============================================

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

define "主要疾病文字資料存在":
  exists (
    [Claim] C
      where exists (
        C.diagnosis D
          where exists (
            D.type.text T
              where T.value is not null
          )
      )
  )

define "報告結論資料存在":
  exists (
    [DiagnosticReport] DR
      where DR.conclusion is not null
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
  exists (
    [Observation] O
      where exists (
        O.code.coding Cdg
          where Cdg.code = '399390009'
            and Cdg in CodeConcept.SNOMED
      )
      and O.value is not null
  )

define "EGFR基因檢測資料存在":
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
                where ComponentCodeCoding.code in CodeConcept.EGFRExon
            )
            and ComponentRecord.value is not null
        )
  )

define "病理或細胞檢查報告資料存在":
  exists (
    [DiagnosticReport] DR
      where exists (
        DR.code.coding Cdg
          where Cdg in CodeConcept.LOINC
            and (
              Cdg.code in CodeConcept.MolecularReport1
              or Cdg.code in CodeConcept.MolecularReport2
            )
      )
      and exists (
        DR.presentedForm P
          where P.url is not null
      )
  )

define "1規則2-1=病理或細胞檢查報告資料存在":
  "病理或細胞檢查報告資料存在"

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

define "續用註記資料存在":
  exists (
    [Claim] C
      where exists (
        C.item I
          where exists (
            I.modifier M
              where exists (
                M.coding Cdg
                  where Cdg in CodeConcept.NHIContinuationStatus
              )
          )
      )
  )

define "醫令類別資料存在":
  exists (
    [Claim] C
      where exists (
        C.item I
          where exists (
            I.productOrService.coding PSC
              where PSC in CodeConcept.NHIOrderType
          )
      )
  )

define "療程期間資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."IsMedicationPlan"(MR, CodeConcept.L01EB04)
  )

define "2規則2-2=療效評估影像資料存在":
  exists (
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

define "3規則3=併用或先前使用EGFR-TKI用藥資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."HasMedicationCode"(
        MR,
        CodeConcept.L01EB01 union CodeConcept.L01EB02 union CodeConcept.L01EB03 union CodeConcept.L01EB07
      )
  )

define "3規則4=每日劑量資料存在":
  exists (
    [MedicationRequest] MR
      where Reusable."IsMedicationPlan"(MR, CodeConcept.L01EB04)
        and exists (
          MR.dosageInstruction DI
            where exists (
              DI.timing.code.coding C
                where C.code = 'QD'
            )
            and exists (
              DI.doseAndRate DR
                where (DR.dose as FHIR.SimpleQuantity) is not null
                  and (DR.dose as FHIR.SimpleQuantity).code = '{tbl}'
            )
        )
  )

//============================================
// 列出檢核項目
define "必要資料皆存在":
  not (
    (
      Reusable."初次申請" and (
          "本次申請紀錄" is null
          or not "主要疾病ICD資料存在"
          or not "EGFR基因檢測資料存在"
          or not "1規則2-1=病理或細胞檢查報告資料存在"
          or not "用藥線別資料存在"
        )
    )
    or (
      Reusable."續用申請" and (
          "本次申請紀錄" is null
          or not "續用註記資料存在"
          or not "醫令類別資料存在"
        )
    )
    or (
      (
          "本次申請紀錄" is null
          or not "療程期間資料存在"
          or not "3規則4=每日劑量資料存在"
        )
    )
  )


//============================================

define function "符合項目"():
  (if Reusable."初次申請" and "主要規定一"
    then '<主要規定一：初次使用條件>\n' +
         '● 1規則1：具有EGFR Exon 19 Del或Exon 21 L858R基因突變之局部侵犯性或轉移性\n' +
         '  ● 1規則1-1：具有EGFR Exon 19 Del或Exon 21 L858R基因突變\n' +
         '  ● 1規則1-2：局部侵犯性或轉移性\n' +
         '  ● 1規則1-3：肺腺癌病患之第一線治療\n' +
         '● 1規則2：初次申請時需檢具確實患有肺腺癌之病理或細胞檢查報告及EGFR基因檢測結果報告\n' +
         '  ● 1規則2-1：肺腺癌之病理或細胞檢查報告\n' +
         '  ● 1規則2-2：EGFR基因檢測結果報告\n\n'
    else if Reusable."初次申請" and (
      "1規則1-1=具有EGFR Exon 19 Del或Exon 21 L858R基因突變"
      or "1規則1-2=局部侵犯性或轉移性"
      or "1規則1-3=肺腺癌病患之第一線治療"
      or "1規則2-1=初次申請時需檢具確實患有肺腺癌之病理或細胞檢查報告"
      or "1規則2-2=檢附EGFR基因檢測結果報告"
    )
      then '<主要規定一：初次使用條件>\n' +
           (if "1規則1-1=具有EGFR Exon 19 Del或Exon 21 L858R基因突變" then '● 1規則1-1：具有EGFR Exon 19 Del或Exon 21 L858R基因突變\n' else '') +
           (if "1規則1-2=局部侵犯性或轉移性" then '● 1規則1-2：局部侵犯性或轉移性\n' else '') +
           (if "1規則1-3=肺腺癌病患之第一線治療" then '● 1規則1-3：肺腺癌病患之第一線治療\n' else '') +
           (if "1規則2-1=初次申請時需檢具確實患有肺腺癌之病理或細胞檢查報告" then '● 1規則2-1：肺腺癌之病理或細胞檢查報告\n' else '') +
           (if "1規則2-2=檢附EGFR基因檢測結果報告" then '● 1規則2-2：EGFR基因檢測結果報告\n' else '') +
           '\n'
      else '') +

  (if Reusable."續用申請" and "主要規定二"
    then '<主要規定二：續用條件－治療持續給付>\n' +
         '● 2規則1：再次申請時需附上治療後相關臨床資料\n' +
         '● 2規則2：每次處方以4週為限，並於給藥4週後追蹤影像檢查評估療效\n' +
         '  ● 2規則2-1：每次處方以4週為限\n' +
         '  ● 2規則2-2：給藥4週後追蹤胸部X光或電腦斷層等影像檢查\n\n'
    else if Reusable."續用申請" and (
      "2規則1=再次申請時需附上治療後相關臨床資料"
      or "2規則2-1=每次處方以4週為限"
      or "2規則2-2=給藥4週後需追蹤胸部X光或電腦斷層等影像檢查評估療效"
    )
      then '<主要規定二：續用條件－治療持續給付>\n' +
           (if "2規則1=再次申請時需附上治療後相關臨床資料" then '● 2規則1：再次申請時需附上治療後相關臨床資料\n' else '') +
           (if "2規則2-1=每次處方以4週為限" then '● 2規則2-1：每次處方以4週為限\n' else '') +
           (if "2規則2-2=給藥4週後需追蹤胸部X光或電腦斷層等影像檢查評估療效" then '● 2規則2-2：給藥4週後追蹤胸部X光或電腦斷層等影像檢查\n' else '') +
           '\n'
      else '') +

  (if "主要規定三"
    then '<主要規定三：藥品使用規則>\n' +
         '● 3規則1：每次申請事前審查之療程以三個月為限（參考資訊）\n' +
         '● 3規則3：與gefitinib、erlotinib、afatinib及dacomitinib僅得擇一使用，如需更換須符合局部侵犯性或轉移性肺腺癌病患\n' +
         '  ● 3規則3-1：僅得擇一使用，除因耐受性不良不得互換（參考資訊）\n' +
         '  ● 3規則3-2：如需更換藥品，須符合具有局部侵犯性或轉移性肺腺癌病患\n' +
         '● 3規則4：每日限用1粒\n\n'
    else if "3規則1=每次申請事前審查之療程以三個月為限" or "3規則3" or "3規則4=每日限用1粒"
      then '<主要規定三：藥品使用規則>\n' +
           (if "3規則1=每次申請事前審查之療程以三個月為限" then '● 3規則1：每次申請事前審查之療程以三個月為限（參考資訊）\n' else '') +
           (if "3規則3" then '● 3規則3：與其他EGFR-TKI擇一使用或更換條件\n' else '') +
           (if "3規則4=每日限用1粒" then '● 3規則4：每日限用1粒\n' else '') +
           '\n'
      else '')


//============================================
// 列出「不符合」項目判斷式 - 條件或代碼不符合
//============================================

define function "不符合項目_條件或代碼不符合"():
  (if Reusable."初次申請" and (
    ("主要疾病ICD資料存在" and not Reusable."ICD-10使用C34")
    or ("EGFR基因檢測資料存在" and not "1規則1-1=具有EGFR Exon 19 Del或Exon 21 L858R基因突變")
    or (("主要疾病文字資料存在" or "影像或檢查報告資料存在" or "癌症分期資料存在") and not "1規則1-2=局部侵犯性或轉移性")
    or (("主要疾病文字資料存在" or "報告結論資料存在" or "用藥線別資料存在") and not "1規則1-3=肺腺癌病患之第一線治療")
    or ("1規則2-1=病理或細胞檢查報告資料存在" and not "1規則2-1=初次申請時需檢具確實患有肺腺癌之病理或細胞檢查報告")
    or ("EGFR基因檢測資料存在" and not "1規則2-2=檢附EGFR基因檢測結果報告")
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "主要疾病ICD資料存在" and not Reusable."ICD-10使用C34" then '▲ 1規則1-3：未符合肺癌ICD C34條件\n' else '') +
         (if "EGFR基因檢測資料存在" and not "1規則1-1=具有EGFR Exon 19 Del或Exon 21 L858R基因突變" then '▲ 1規則1-1：未符合EGFR Exon 19 Del或Exon 21 L858R基因突變條件\n' else '') +
         (if not "1規則1-2=局部侵犯性或轉移性" then '▲ 1規則1-2：未符合局部侵犯性或轉移性條件\n' else '') +
         (if not "1規則1-3=肺腺癌病患之第一線治療" then '▲ 1規則1-3：未符合肺腺癌病患第一線治療條件\n' else '') +
         (if "1規則2-1=病理或細胞檢查報告資料存在" and not "1規則2-1=初次申請時需檢具確實患有肺腺癌之病理或細胞檢查報告" then '▲ 1規則2-1：未符合肺腺癌病理或細胞檢查報告條件\n' else '') +
         (if "EGFR基因檢測資料存在" and not "1規則2-2=檢附EGFR基因檢測結果報告" then '▲ 1規則2-2：未符合EGFR基因檢測結果報告條件\n' else '') +
         '\n'
    else '') +

  (if Reusable."續用申請" and (
    ("影像或檢查報告資料存在" and not "2規則1=再次申請時需附上治療後相關臨床資料")
    or ("療程期間資料存在" and not "2規則2-1=每次處方以4週為限")
    or ("2規則2-2=療效評估影像資料存在" and not "2規則2-2=給藥4週後需追蹤胸部X光或電腦斷層等影像檢查評估療效")
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if "影像或檢查報告資料存在" and not "2規則1=再次申請時需附上治療後相關臨床資料" then '▲ 2規則1：未符合再次申請治療後相關臨床資料條件\n' else '') +
         (if "療程期間資料存在" and not "2規則2-1=每次處方以4週為限" then '▲ 2規則2-1：未符合每次處方以4週為限條件\n' else '') +
         (if "2規則2-2=療效評估影像資料存在" and not "2規則2-2=給藥4週後需追蹤胸部X光或電腦斷層等影像檢查評估療效" then '▲ 2規則2-2：未符合給藥4週後影像檢查評估療效條件\n' else '') +
         '\n'
    else '') +

  (if (
    ("療程期間資料存在" and not "3規則1=每次申請事前審查之療程以三個月為限")
    or ("3規則3=併用或先前使用EGFR-TKI用藥資料存在" and not "3規則3")
    or ("3規則4=每日劑量資料存在" and not "3規則4=每日限用1粒")
  )
    then '<主要規定三：藥品使用規則>\n' +
         (if "療程期間資料存在" and not "3規則1=每次申請事前審查之療程以三個月為限" then '▲ 3規則1：未符合每次申請事前審查療程以三個月為限條件（參考資訊）\n' else '') +
         (if "3規則3=併用或先前使用EGFR-TKI用藥資料存在" and not "3規則3" then '▲ 3規則3：未符合與其他EGFR-TKI擇一使用或更換條件\n' else '') +
         (if "3規則4=每日劑量資料存在" and not "3規則4=每日限用1粒" then '▲ 3規則4：未符合每日限用1粒條件\n' else '') +
         '\n'
    else '')


//============================================
// 列出「不符合」項目判斷式 - 必要資料未填寫
//============================================

define function "不符合項目_必要資料未填寫"():
  (if Reusable."初次申請" and (
    "本次申請紀錄" is null
    or not "主要疾病ICD資料存在"
    or not "EGFR基因檢測資料存在"
    or not "1規則2-1=病理或細胞檢查報告資料存在"
    or not "用藥線別資料存在"
  )
    then '<主要規定一：初次使用條件>\n' +
         (if "本次申請紀錄" is null then '▲ 1條件申請醫令：未提供Osimertinib申請醫令資料\n' else '') +
         (if not "主要疾病ICD資料存在" then '▲ 1規則1-3：未提供主要疾病ICD診斷資料\n' else '') +
         (if not "EGFR基因檢測資料存在" then '▲ 1規則1-1/1規則2-2：未提供EGFR基因檢測資料\n' else '') +
         (if not "1規則2-1=病理或細胞檢查報告資料存在" then '▲ 1規則2-1：未提供病理或細胞檢查報告資料\n' else '') +
         (if not "用藥線別資料存在" then '▲ 1規則1-3：未提供用藥線別資料\n' else '') +
         '\n'
    else '') +

  (if Reusable."續用申請" and (
    "本次申請紀錄" is null
    or not "續用註記資料存在"
    or not "醫令類別資料存在"
  )
    then '<主要規定二：續用條件－治療持續給付>\n' +
         (if "本次申請紀錄" is null then '▲ 2條件申請醫令：未提供Osimertinib申請醫令資料\n' else '') +
         (if not "續用註記資料存在" then '▲ 2規則1：未提供續用註記資料\n' else '') +
         (if not "醫令類別資料存在" then '▲ 2規則1：未提供醫令類別資料\n' else '') +
         '\n'
    else '') +

  (if (
    "本次申請紀錄" is null
    or not "療程期間資料存在"
    or not "3規則4=每日劑量資料存在"
  )
    then '<主要規定三：藥品使用規則>\n' +
         (if "本次申請紀錄" is null then '▲ 3條件申請醫令：未提供Osimertinib申請醫令資料\n' else '') +
         (if not "療程期間資料存在" then '▲ 3規則1：未提供療程起迄日期資料（參考資訊）\n' else '') +
         (if not "3規則4=每日劑量資料存在" then '▲ 3規則4：未提供每日劑量資料\n' else '') +
         '\n'
    else '')

//============================================
// 審核結果
//============================================

define "肺癌Osimertinib申請結果_布林":
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

define "肺癌Osimertinib申請結果":
  if Reusable."初次申請" and "主要規定一" and "主要規定三_核心條件"
  then '✓通過：初次使用－肺癌 Osimertinib（第一線）用藥申請'
  else if Reusable."續用申請" and "主要規定二" and "主要規定三_核心條件"
  then '✓通過：續用－肺癌 Osimertinib（第一線）用藥申請'
  else if Reusable."初次申請"
  then '✖不通過：初次使用－肺癌 Osimertinib（第一線）用藥申請'
  else if Reusable."續用申請"
  then '✖不通過：續用－肺癌 Osimertinib（第一線）用藥申請'
  else '✖不通過：無法判定申請類型－肺癌 Osimertinib（第一線）用藥申請'

define "報告總結":
  '\n=== 肺癌之 Osimertinib（第一線）申請審核報告 ===\n' +
  '\n※ 備註：標示為「參考資訊」之檢核項目，係供審核參酌使用，不作為最終【申請結果】判定之依據。\n' +
  '\n【申請類型】' + Reusable."申請類型" + '\n' +
  '\n【●符合項目】\n' +
  (if "符合項目"() = '' then '無\n' else "符合項目"()) +
  '\n【▲不符合項目 - 必要資料未填寫】\n' +
  (if "不符合項目_必要資料未填寫"() = '' then '無\n' else "不符合項目_必要資料未填寫"()) +
  '\n【▲不符合項目 - 條件或代碼不符合】\n' +
  (if "不符合項目_條件或代碼不符合"() = '' then '無\n' else "不符合項目_條件或代碼不符合"()) +
  '\n【申請結果】\n' +
  "肺癌Osimertinib申請結果" +
  '\n===============================================\n'
