*&---------------------------------------------------------------------*
*& Program     : ZSO_ALV_REPORT
*& Title       : Custom Sales Order ALV Report
*& Author      : [Your Name]
*& Date        : April 2026
*& Description : Displays Sales Orders with Customer, Material, Value
*&               and Status details using SAP ALV Grid Display.
*&               Supports filtering by Company Code, Date Range,
*&               Sales Organization and Document Status.
*& Tcode       : ZSO_ALV (Custom Transaction)
*&---------------------------------------------------------------------*

REPORT zso_alv_report
  NO STANDARD PAGE HEADING
  LINE-SIZE 255
  MESSAGE-ID zmsg_so.

*----------------------------------------------------------------------*
* TYPE DECLARATIONS
*----------------------------------------------------------------------*
TYPES:
  BEGIN OF ty_sales_order,
    vbeln    TYPE vbak-vbeln,       " Sales Order Number
    erdat    TYPE vbak-erdat,       " Creation Date
    auart    TYPE vbak-auart,       " Sales Doc Type
    vkorg    TYPE vbak-vkorg,       " Sales Organization
    kunnr    TYPE vbak-kunnr,       " Sold-to Party (Customer)
    name1    TYPE kna1-name1,       " Customer Name
    matnr    TYPE vbap-matnr,       " Material Number
    arktx    TYPE vbap-arktx,       " Material Description
    kwmeng   TYPE vbap-kwmeng,      " Order Quantity
    meins    TYPE vbap-meins,       " Unit of Measure
    netpr    TYPE vbap-netpr,       " Net Price per Unit
    netwr    TYPE vbap-netwr,       " Net Value of Item
    waerk    TYPE vbak-waerk,       " Currency
    gbsta    TYPE vbuk-gbsta,       " Overall Status
    lfsta    TYPE vbuk-lfsta,       " Delivery Status
    fksta    TYPE vbuk-fksta,       " Billing Status
    light    TYPE c,                " Traffic Light (ALV)
  END OF ty_sales_order.

TYPES: tt_sales_order TYPE STANDARD TABLE OF ty_sales_order.

*----------------------------------------------------------------------*
* DATA DECLARATIONS
*----------------------------------------------------------------------*
DATA:
  gt_sales_order TYPE tt_sales_order,
  gs_sales_order TYPE ty_sales_order,
  gt_fieldcat    TYPE slis_t_fieldcat_alv,
  gs_fieldcat    TYPE slis_fieldcat_alv,
  gs_layout      TYPE slis_layout_alv,
  gs_variant     TYPE disvariant,
  gt_sort        TYPE slis_t_sortinfo_alv,
  gs_sort        TYPE slis_sortinfo_alv,
  gs_events      TYPE slis_alv_event,
  gt_events      TYPE slis_t_event.

*----------------------------------------------------------------------*
* SELECTION SCREEN
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS:
    s_vkorg FOR gs_sales_order-vkorg,     " Sales Organization
    s_kunnr FOR gs_sales_order-kunnr,     " Customer Number
    s_erdat FOR gs_sales_order-erdat,     " Creation Date Range
    s_auart FOR gs_sales_order-auart.     " Sales Document Type
  PARAMETERS:
    p_gbsta TYPE vbuk-gbsta,              " Overall Status Filter
    p_max   TYPE i DEFAULT 500.           " Max Records
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
  PARAMETERS:
    p_var   TYPE disvariant-variant,      " ALV Layout Variant
    p_top   AS CHECKBOX DEFAULT 'X'.      " Show Top-of-Page
SELECTION-SCREEN END OF BLOCK b2.

*----------------------------------------------------------------------*
* INITIALIZATION
*----------------------------------------------------------------------*
INITIALIZATION.
  s_erdat-low  = sy-datum - 90.   " Default: Last 90 days
  s_erdat-high = sy-datum.
  s_erdat-sign = 'I'.
  s_erdat-option = 'BT'.
  APPEND s_erdat.

*----------------------------------------------------------------------*
* START OF SELECTION
*----------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM fetch_data.
  PERFORM process_data.

END-OF-SELECTION.
  PERFORM display_alv.

*----------------------------------------------------------------------*
*& FORM FETCH_DATA
*----------------------------------------------------------------------*
FORM fetch_data.

  DATA: lt_vbeln TYPE STANDARD TABLE OF vbak-vbeln.

  " Step 1: Fetch Sales Order Header data
  SELECT vbak~vbeln
         vbak~erdat
         vbak~auart
         vbak~vkorg
         vbak~kunnr
         vbak~waerk
         kna1~name1
    INTO TABLE @DATA(lt_header)
    FROM vbak
    INNER JOIN kna1 ON kna1~kunnr = vbak~kunnr
    WHERE vbak~vkorg IN @s_vkorg
      AND vbak~kunnr IN @s_kunnr
      AND vbak~erdat IN @s_erdat
      AND vbak~auart IN @s_auart
    UP TO @p_max ROWS.

  IF lt_header IS INITIAL.
    MESSAGE 'No Sales Orders found for the given selection.' TYPE 'S'
            DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  " Collect order numbers for item fetch
  lt_vbeln = VALUE #( FOR wa IN lt_header ( wa-vbeln ) ).

  " Step 2: Fetch Sales Order Item data
  SELECT vbap~vbeln
         vbap~posnr
         vbap~matnr
         vbap~arktx
         vbap~kwmeng
         vbap~meins
         vbap~netpr
         vbap~netwr
    INTO TABLE @DATA(lt_items)
    FROM vbap
    WHERE vbeln IN ( SELECT vbeln FROM vbak WHERE vbeln IN @lt_vbeln ).

  " Step 3: Fetch Status data from VBUK
  SELECT vbeln gbsta lfsta fksta
    INTO TABLE @DATA(lt_status)
    FROM vbuk
    WHERE vbeln IN ( SELECT vbeln FROM vbak WHERE vbeln IN @lt_vbeln ).

  " Sort for faster access
  SORT lt_header BY vbeln.
  SORT lt_items  BY vbeln.
  SORT lt_status BY vbeln.

  " Step 4: Build output table
  LOOP AT lt_items INTO DATA(ls_item).

    READ TABLE lt_header INTO DATA(ls_hdr)
      WITH KEY vbeln = ls_item-vbeln BINARY SEARCH.
    IF sy-subrc <> 0. CONTINUE. ENDIF.

    READ TABLE lt_status INTO DATA(ls_sts)
      WITH KEY vbeln = ls_item-vbeln BINARY SEARCH.

    " Apply overall status filter if specified
    IF p_gbsta IS NOT INITIAL AND ls_sts-gbsta <> p_gbsta.
      CONTINUE.
    ENDIF.

    CLEAR gs_sales_order.
    gs_sales_order-vbeln  = ls_item-vbeln.
    gs_sales_order-erdat  = ls_hdr-erdat.
    gs_sales_order-auart  = ls_hdr-auart.
    gs_sales_order-vkorg  = ls_hdr-vkorg.
    gs_sales_order-kunnr  = ls_hdr-kunnr.
    gs_sales_order-name1  = ls_hdr-name1.
    gs_sales_order-matnr  = ls_item-matnr.
    gs_sales_order-arktx  = ls_item-arktx.
    gs_sales_order-kwmeng = ls_item-kwmeng.
    gs_sales_order-meins  = ls_item-meins.
    gs_sales_order-netpr  = ls_item-netpr.
    gs_sales_order-netwr  = ls_item-netwr.
    gs_sales_order-waerk  = ls_hdr-waerk.
    gs_sales_order-gbsta  = ls_sts-gbsta.
    gs_sales_order-lfsta  = ls_sts-lfsta.
    gs_sales_order-fksta  = ls_sts-fksta.

    APPEND gs_sales_order TO gt_sales_order.
  ENDLOOP.

ENDFORM.

*----------------------------------------------------------------------*
*& FORM PROCESS_DATA
*----------------------------------------------------------------------*
FORM process_data.
  " Assign traffic light based on overall status
  LOOP AT gt_sales_order ASSIGNING FIELD-SYMBOL(<fs_so>).
    CASE <fs_so>-gbsta.
      WHEN 'A'. <fs_so>-light = '1'.  " Green  - Open
      WHEN 'B'. <fs_so>-light = '2'.  " Yellow - In Process
      WHEN 'C'. <fs_so>-light = '1'.  " Green  - Completed
      WHEN 'D'. <fs_so>-light = '3'.  " Red    - Rejected/Blocked
      WHEN OTHERS. <fs_so>-light = '2'.
    ENDCASE.
  ENDLOOP.

  " Sort by Sales Order descending (latest first)
  SORT gt_sales_order BY vbeln DESCENDING.

ENDFORM.

*----------------------------------------------------------------------*
*& FORM BUILD_FIELDCAT
*----------------------------------------------------------------------*
FORM build_fieldcat.

  DATA: lv_col TYPE i VALUE 1.

  DEFINE add_field.
    CLEAR gs_fieldcat.
    gs_fieldcat-col_pos    = lv_col.
    gs_fieldcat-fieldname  = &1.
    gs_fieldcat-tabname    = 'GT_SALES_ORDER'.
    gs_fieldcat-seltext_l  = &2.
    gs_fieldcat-seltext_m  = &3.
    gs_fieldcat-outputlen  = &4.
    gs_fieldcat-just       = &5.
    gs_fieldcat-do_sum     = &6.
    APPEND gs_fieldcat TO gt_fieldcat.
    lv_col = lv_col + 1.
  END-OF-DEFINITION.

  "           Field      Long Text              Med Text   Len Just Sum
  add_field 'LIGHT'    'Status'               'Stat'      4   'C'  ' '.
  add_field 'VBELN'    'Sales Order'          'SO No.'   10   'L'  ' '.
  add_field 'ERDAT'    'Created On'           'Cr.Date'  10   'L'  ' '.
  add_field 'AUART'    'Doc. Type'            'DocType'   4   'L'  ' '.
  add_field 'VKORG'    'Sales Org.'           'SOrg.'     4   'L'  ' '.
  add_field 'KUNNR'    'Customer No.'         'Cust.No'  10   'L'  ' '.
  add_field 'NAME1'    'Customer Name'        'Cust.Nm'  35   'L'  ' '.
  add_field 'MATNR'    'Material No.'         'Mat.No'   18   'L'  ' '.
  add_field 'ARKTX'    'Material Description' 'Mat.Desc' 40   'L'  ' '.
  add_field 'KWMENG'   'Order Qty'            'Ord.Qty'  13   'R'  ' '.
  add_field 'MEINS'    'UoM'                  'UoM'       3   'L'  ' '.
  add_field 'NETPR'    'Net Price'            'NetPrc'   15   'R'  ' '.
  add_field 'NETWR'    'Net Value'            'Net Val'  15   'R'  'X'.
  add_field 'WAERK'    'Currency'             'Curr'      5   'L'  ' '.
  add_field 'GBSTA'    'Overall Status'       'OvSts'     1   'C'  ' '.
  add_field 'LFSTA'    'Delivery Status'      'DlvSts'    1   'C'  ' '.
  add_field 'FKSTA'    'Billing Status'       'BlgSts'    1   'C'  ' '.

  " Set traffic light column
  DATA(ls_fc_light) = VALUE slis_fieldcat_alv(
    fieldname = 'LIGHT'
    tabname   = 'GT_SALES_ORDER'
    icon      = abap_true
  ).

ENDFORM.

*----------------------------------------------------------------------*
*& FORM BUILD_LAYOUT
*----------------------------------------------------------------------*
FORM build_layout.

  gs_layout-zebra            = abap_true.        " Striped rows
  gs_layout-colwidth_optimize = abap_true.        " Auto column width
  gs_layout-info_fieldname   = 'LIGHT'.          " Traffic light
  gs_layout-totals_text      = 'Grand Total'.
  gs_layout-detail_popup     = abap_true.
  gs_layout-box_fieldname    = ''.
  gs_layout-get_selinfos     = abap_true.

ENDFORM.

*----------------------------------------------------------------------*
*& FORM BUILD_SORT
*----------------------------------------------------------------------*
FORM build_sort.

  CLEAR gs_sort.
  gs_sort-fieldname = 'VKORG'.
  gs_sort-tabname   = 'GT_SALES_ORDER'.
  gs_sort-spos      = 1.
  gs_sort-up        = abap_true.
  gs_sort-subtot    = abap_true.     " Subtotal by Sales Org
  APPEND gs_sort TO gt_sort.

  CLEAR gs_sort.
  gs_sort-fieldname = 'KUNNR'.
  gs_sort-tabname   = 'GT_SALES_ORDER'.
  gs_sort-spos      = 2.
  gs_sort-up        = abap_true.
  gs_sort-subtot    = abap_true.     " Subtotal by Customer
  APPEND gs_sort TO gt_sort.

ENDFORM.

*----------------------------------------------------------------------*
*& FORM DISPLAY_ALV
*----------------------------------------------------------------------*
FORM display_alv.

  PERFORM build_fieldcat.
  PERFORM build_layout.
  PERFORM build_sort.

  " Set variant for saving layouts
  gs_variant-report  = sy-repid.
  gs_variant-variant = p_var.

  " Call ALV Grid Display
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program      = sy-repid
      i_callback_top_of_page  = 'TOP_OF_PAGE'
      i_callback_user_command = 'USER_COMMAND'
      is_layout               = gs_layout
      it_fieldcat             = gt_fieldcat
      it_sort                 = gt_sort
      is_variant              = gs_variant
      i_save                  = 'A'
      i_default               = 'X'
    TABLES
      t_outtab                = gt_sales_order
    EXCEPTIONS
      program_error           = 1
      OTHERS                  = 2.

  IF sy-subrc <> 0.
    MESSAGE 'Error displaying ALV Report.' TYPE 'E'.
  ENDIF.

ENDFORM.

*----------------------------------------------------------------------*
*& FORM TOP_OF_PAGE  (ALV Callback)
*----------------------------------------------------------------------*
FORM top_of_page.

  DATA: lt_header TYPE slis_t_listheader,
        ls_header TYPE slis_listheader.

  " Title
  ls_header-typ  = 'H'.
  ls_header-info = 'Custom Sales Order Report — TechVista Enterprises'.
  APPEND ls_header TO lt_header.

  " Subtitle: Selection
  ls_header-typ  = 'S'.
  ls_header-key  = 'Sales Org:'.
  ls_header-info = COND #( WHEN s_vkorg IS INITIAL THEN 'All'
                            ELSE s_vkorg-low ).
  APPEND ls_header TO lt_header.

  ls_header-typ  = 'S'.
  ls_header-key  = 'Date Range:'.
  ls_header-info = |{ s_erdat-low DATE = USER } - { s_erdat-high DATE = USER }|.
  APPEND ls_header TO lt_header.

  ls_header-typ  = 'S'.
  ls_header-key  = 'Run By:'.
  ls_header-info = |{ sy-uname } on { sy-datum DATE = USER } { sy-uzeit TIME = USER }|.
  APPEND ls_header TO lt_header.

  " Record Count
  ls_header-typ  = 'A'.
  ls_header-info = |Total Records: { lines( gt_sales_order ) }|.
  APPEND ls_header TO lt_header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = lt_header.

ENDFORM.

*----------------------------------------------------------------------*
*& FORM USER_COMMAND  (ALV Callback — Double-click drill-down)
*----------------------------------------------------------------------*
FORM user_command USING r_ucomm     TYPE sy-ucomm
                        rs_selfield TYPE slis_selfield.

  CASE r_ucomm.
    WHEN '&IC1'.   " Double click on row
      READ TABLE gt_sales_order INTO gs_sales_order
        INDEX rs_selfield-tabindex.
      IF sy-subrc = 0.
        " Navigate to VA03 — Display Sales Order
        SET PARAMETER ID 'AUN' FIELD gs_sales_order-vbeln.
        CALL TRANSACTION 'VA03' AND SKIP FIRST SCREEN.
      ENDIF.
  ENDCASE.

ENDFORM.
