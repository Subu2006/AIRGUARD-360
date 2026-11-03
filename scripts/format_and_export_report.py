import win32com.client as win32
import os

docx_path = os.path.abspath('reports/AIRGUARD_360_Project_Report.docx')
pdf_path  = os.path.abspath('reports/AIRGUARD_360_Project_Report.pdf')

print(f">> [REPORT FORMATTER] Opening Microsoft Word to format: {docx_path}")

try:
    word = win32.gencache.EnsureDispatch('Word.Application')
except Exception:
    word = win32.Dispatch('Word.Application')

word.Visible = False

try:
    doc = word.Documents.Open(docx_path)
    
    # 1. Page Setup: A4, 1-inch margins across all sections
    for sec in doc.Sections:
        sec.PageSetup.PaperSize = 7 # wdPaperA4 = 7
        sec.PageSetup.TopMargin = 72 # 1 inch = 72 pt
        sec.PageSetup.BottomMargin = 72
        sec.PageSetup.LeftMargin = 72
        sec.PageSetup.RightMargin = 72
        
    # 2. Update standard styles
    try:
        style_normal = doc.Styles("Normal")
        style_normal.Font.Name = "Times New Roman"
        style_normal.Font.Size = 12
        style_normal.ParagraphFormat.LineSpacingRule = 1 # 1 = wdLineSpace1pt5 (1.5 line spacing)
        style_normal.ParagraphFormat.SpaceAfter = 6
        style_normal.ParagraphFormat.SpaceBefore = 0
    except Exception as e:
        print("   Normal style error:", e)

    try:
        style_h1 = doc.Styles("Heading 1")
        style_h1.Font.Name = "Times New Roman"
        style_h1.Font.Size = 16
        style_h1.Font.Bold = True
        style_h1.ParagraphFormat.SpaceBefore = 14
        style_h1.ParagraphFormat.SpaceAfter = 6
    except Exception as e:
        print("   Heading 1 style error:", e)

    try:
        style_h2 = doc.Styles("Heading 2")
        style_h2.Font.Name = "Times New Roman"
        style_h2.Font.Size = 14
        style_h2.Font.Bold = True
        style_h2.ParagraphFormat.SpaceBefore = 10
        style_h2.ParagraphFormat.SpaceAfter = 4
    except Exception as e:
        print("   Heading 2 style error:", e)

    try:
        style_h3 = doc.Styles("Heading 3")
        style_h3.Font.Name = "Times New Roman"
        style_h3.Font.Size = 12
        style_h3.Font.Bold = True
        style_h3.Font.Italic = True
        style_h3.ParagraphFormat.SpaceBefore = 6
        style_h3.ParagraphFormat.SpaceAfter = 2
    except Exception as e:
        print("   Heading 3 style error:", e)

    # 3. Format Cover Page (all paragraphs before CERTIFICATE)
    print("   Formatting Cover Page according to prescribed guidelines...")
    cover_ended = False
    for p in doc.Paragraphs:
        txt = p.Range.Text.strip()
        if "CERTIFICATE" in txt:
            cover_ended = True
            break
        if not cover_ended:
            p.Alignment = 1 # wdAlignParagraphCenter = 1
            p.Range.Font.Name = "Times New Roman"
            if "AIRGUARD 360" in txt or "PROJECT REPORT" in txt:
                p.Range.Font.Bold = True
                if "AIRGUARD 360" in txt:
                    p.Range.Font.Size = 16
                else:
                    p.Range.Font.Size = 12
            elif "Lovely School" in txt or "Lovely Professional University" in txt or "Discipline of Computer" in txt:
                p.Range.Font.Bold = True
                p.Range.Font.Size = 12
            else:
                p.Range.Font.Size = 12
                if any(k in txt for k in ["Subrat Panigrahi", "26143073", "Mr. Jaffar Amin Chacket", "INT232"]):
                    p.Range.Font.Bold = True

    # 4. Insert Table of Contents at TOC_PLACEHOLDER
    print("   Checking Table of Contents placement...")
    for p in doc.Paragraphs:
        txt = p.Range.Text.strip()
        if "TOC_PLACEHOLDER" in txt:
            p.Range.Text = ""
            doc.TablesOfContents.Add(Range=p.Range, LowerHeadingLevel=3, UpperHeadingLevel=1)
            print("   Successfully inserted Table of Contents at designated location!")
            break

    # 5. Format all Tables
    print(f"   Formatting {doc.Tables.Count} tables...")
    for t in doc.Tables:
        t.Range.Font.Name = "Times New Roman"
        t.Range.Font.Size = 10.5
        t.Range.ParagraphFormat.LineSpacingRule = 0 # Single space within tables
        t.Range.ParagraphFormat.SpaceAfter = 2
        t.Range.ParagraphFormat.SpaceBefore = 1
        t.Rows.Alignment = 1 # Center align table
        try:
            t.Rows(1).Range.Font.Bold = True
            t.Rows(1).HeadingFormat = True # Repeat header on each page
        except Exception:
            pass

    # 6. Update all Fields and Table of Contents
    print("   Updating fields and Table of Contents...")
    doc.Fields.Update()
    for toc in doc.TablesOfContents:
        toc.Update()

    # 7. Compute Document Statistics
    pages = doc.ComputeStatistics(2) # wdStatisticPages = 2
    words = doc.ComputeStatistics(0) # wdStatisticWords = 0
    paras = doc.ComputeStatistics(4) # wdStatisticParagraphs = 4
    
    print("\n=======================================================")
    print(f"DOCUMENT STATISTICS FOR FINAL REPORT:")
    print(f"Total Pages: {pages} (Prescribed Requirement: 30 to 80 pages)")
    print(f"Total Words: {words:,}")
    print(f"Total Paragraphs: {paras}")
    print("=======================================================\n")
    
    # 8. Save DOCX
    doc.Save()
    print(f"   Saved finalized DOCX: {docx_path}")
    
    # 9. Export native PDF (wdFormatPDF = 17)
    print(f"   Exporting native PDF: {pdf_path}...")
    doc.SaveAs(pdf_path, 17)
    print(f"   Successfully exported PDF! Size: {os.path.getsize(pdf_path):,} bytes")
    
    doc.Close()
finally:
    word.Quit()

print(">> [SUCCESS] Report formatting and PDF compilation successfully completed!")
