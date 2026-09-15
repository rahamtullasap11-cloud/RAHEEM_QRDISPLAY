# RAHEEM_QRDISPLAY
QR CODE DISPLAY
RAP QR-code project, I recommend the following step-by-step approach. Since you already have the QR URL being generated successfully, we will focus on the complete flow from RAP action → QR URL → Fiori Elements Object Page → actual QR image.

Overall Flow
Fiori Elements List Report
        │
        │ Select one/multiple records
        ▼
     QRGEN Action
        │
        ▼
RAP Behavior Implementation
        │
        ├── READ selected Material
        │
        ├── Build QR Text
        │
        ├── Generate QR URL
        │
        └── UPDATE same Material
                │
                ▼
             QR_URL
                │
                ▼
Fiori Elements Object Page
                │
                ▼
          sap.m.Image
                │
                ▼
          Actual QR Code
Step 1 — Create the Database Table

Create a table such as ZMAT_QR.

Example:

@EndUserText.label : 'Material QR Table'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
define table zmat_qr {

  key client : abap.clnt not null;

  key matnr  : abap.char(18) not null;

  maktx      : abap.char(40);
  mtart      : abap.char(4);

  qr_text    : abap.char(500);
  qr_url     : abap.char(1000);

}

For your current approach, the important fields are:

Field	Purpose
MATNR	Material number
MAKTX	Material description
MTART	Material type
QR_TEXT	Text encoded in QR
QR_URL	URL of generated QR image
Important

Do not store the QR URL in an XSTRING field.

You currently have a URL such as:

https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=...

Therefore:

QR_URL → CHAR

is appropriate.

Step 2 — Create Interface CDS View

Create:

ZI_MAT_QR

Example:

@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Material QR Code'
define root view entity ZI_MAT_QR
  as select from zmat_qr
{
  key matnr as Matnr,

      maktx as Maktx,

      mtart as Mtart,

      qr_text as QrText,

      @Semantics.imageUrl: true
      qr_url as QrUrl
}

The important annotation is:

@Semantics.imageUrl: true
qr_url as QrUrl

This tells the UI metadata that QrUrl represents an image URL.

Step 3 — Create Metadata Extension

Create:

ZI_MAT_QR

metadata extension.

For example:

@Metadata.layer: #CORE

annotate view ZI_MAT_QR with
{

  @UI.identification: [
    {
      position: 10,
      label: 'Material Number'
    }
  ]
  Matnr;

  @UI.identification: [
    {
      position: 20,
      label: 'Material Description'
    }
  ]
  Maktx;

  @UI.identification: [
    {
      position: 30,
      label: 'Material Type'
    }
  ]
  Mtart;

  @UI.identification: [
    {
      position: 40,
      label: 'QR Text'
    }
  ]
  QrText;

}
Don't do this

Don't expect this:

@UI.identification: [
  {
    position: 50,
    label: 'QR CODE'
  }
]
QrUrl;

to automatically display the QR image.

It will generally display the URL as a field.

For your requirement, we will use a UI5 Image control.

Step 4 — Create Projection CDS

Create:

ZC_MAT_QR

Example:

@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Material QR Code'
define root view entity ZC_MAT_QR
  provider contract transactional_query
  as projection on ZI_MAT_QR
{
  key Matnr,
      Maktx,
      Mtart,
      QrText,
      QrUrl
}
Step 5 — Create Interface Behavior Definition

Create behavior for ZI_MAT_QR.

managed implementation in class zbp_i_mat_qr unique;
strict ( 2 );

define behavior for ZI_MAT_QR
persistent table zmat_qr
lock master
authorization master ( instance )
{
  update;

  action QRGEN result [1] $self;
}

The important part is:

action QRGEN result [1] $self;

This creates your custom action.

Step 6 — Create Projection Behavior

Create behavior projection:

projection;
strict ( 2 );

define behavior for ZC_MAT_QR
{
  use update;
  use action QRGEN;
}

Now the QRGEN action can be exposed to the Fiori Elements application.

Step 7 — Create QR Generator Class

Since your current solution generates a QR image URL using QRServer, create a reusable class.

For example:

ZCL_QR_GENERATOR
Definition
CLASS zcl_qr_generator DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    CLASS-METHODS generate_qr_url
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_url) TYPE string.

ENDCLASS.
Implementation
CLASS zcl_qr_generator IMPLEMENTATION.

  METHOD generate_qr_url.

    DATA(lv_encoded_text) =
      escape(
        val    = iv_text
        format = cl_abap_format=>e_url ).

    rv_url =
      |https://api.qrserver.com/v1/create-qr-code/?size=300x300&data={ lv_encoded_text }|.

  ENDMETHOD.

ENDCLASS.

Now your RAP code doesn't need to know how the URL is constructed.

Step 8 — Implement QRGEN Action

Open the behavior implementation class:

ZBP_I_MAT_QR

Implement:

METHOD qrgen.

  READ ENTITIES OF zi_mat_qr IN LOCAL MODE
    ENTITY ZI_MAT_QR
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_materials).

  LOOP AT lt_materials ASSIGNING FIELD-SYMBOL(<ls_material>).

    DATA(lv_qr_text) =
      |Material: { <ls_material>-Matnr }; | &&
      |Description: { <ls_material>-Maktx }; | &&
      |Type: { <ls_material>-Mtart }|.

    DATA(lv_qr_url) =
      zcl_qr_generator=>generate_qr_url(
        iv_text = lv_qr_text ).

    MODIFY ENTITIES OF zi_mat_qr IN LOCAL MODE
      ENTITY ZI_MAT_QR
      UPDATE FIELDS ( QrText QrUrl )
      WITH VALUE #(
        (
          %tky   = <ls_material>-%tky
          QrText = lv_qr_text
          QrUrl  = lv_qr_url
        )
      )
      FAILED DATA(lt_failed)
      REPORTED DATA(lt_reported).

  ENDLOOP.

  READ ENTITIES OF zi_mat_qr IN LOCAL MODE
    ENTITY ZI_MAT_QR
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_result).

  result = VALUE #(
    FOR ls_result IN lt_result
    (
      %tky   = ls_result-%tky
      %param = ls_result
    )
  ).

ENDMETHOD.
Step 9 — Test the RAP Action First

Before doing the Fiori UI extension, test the backend.

Go to your Fiori Elements application.

Select:

Material 1300

Click:

Generate QR

The backend should create something like:

QR_TEXT
Material: 000000000000001300;
Description: TATA MOTORS;
Type: EA
QR_URL
https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=...

At this point, your backend is working.

Step 10 — Check the Database

After executing QRGEN, check:

ZMAT_QR

You should see:

MATNR = 1300

MAKTX = TATA MOTORS

MTART = EA

QR_TEXT =
Material: 000000000000001300; Description: TATA MOTORS; Type: EA

QR_URL =
https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=...

If these values are saved, RAP is working correctly.

Step 11 — Understand Your Current Problem

Currently Fiori is showing:

QR CODE
https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=...

This means:

Backend
   ↓
QR_URL
   ↓
Fiori
   ↓
String field

Fiori sees QR_URL as text.

We need:

QR_URL
   ↓
sap.m.Image
   ↓
Actual QR image
Step 12 — Create a UI5 Fragment

Create a fragment such as:

webapp/ext/fragment/QRCode.fragment.xml

Use:

<core:FragmentDefinition
    xmlns="sap.m"
    xmlns:core="sap.ui.core">

    <VBox class="sapUiMediumMargin">

        <Title
            text="QR CODE"
            level="H4" />

        <Image
            src="{QrUrl}"
            width="300px"
            height="300px"
            densityAware="false"
            decorative="false" />

    </VBox>

</core:FragmentDefinition>

The key line is:

<Image src="{QrUrl}" />

The browser will request:

QrUrl

and display the returned QR image.

Step 13 — Add the Fragment to the Object Page

This is the part that connects your custom UI to Fiori Elements.

Your application should have a controller extension and manifest extension.

Conceptually:

Fiori Elements Object Page
          │
          ▼
     Extension Point
          │
          ▼
   QRCode.fragment.xml
          │
          ▼
      sap.m.Image
          │
          ▼
        QrUrl

Depending on your generated Fiori Elements application/template and UI5 version, the exact extension point configuration differs.

For the Object Page, we can add a custom section/facet containing your fragment.

Step 14 — Add a Custom Section

The desired Object Page becomes:

Material QR Code

Identification
────────────────────────────

Material Number       1300
Material Description  TATA MOTORS
Material Type         EA
QR Text               Material: 000000000000001300...

QR CODE
────────────────────────────

       ███████████
       ██       ██
       ██ ████  ██
       ██ █  █  ██
       ██  ████ ██
       ███████████


This is much better than displaying:

QR CODE
https://api.qrserver.com/...
Step 15 — Add Header Image Option

There is also a much simpler option if you don't specifically need the QR inside Identification.

You can put the QR image into the Object Page Header.

Your CDS already has:

@Semantics.imageUrl: true
qr_url as QrUrl

Then use:

@UI.headerInfo: {
  typeName: 'Material',
  typeNamePlural: 'Materials',

  title: {
    type: #STANDARD,
    value: 'Matnr'
  },

  description: {
    type: #STANDARD,
    value: 'Maktx'
  },

  imageUrl: 'QrUrl'
}

This allows the Object Page header to use the QR URL as the entity image.

Step 16 — Recommended Final Architecture

For your current project, I recommend this:

Backend
ZMAT_QR
   │
   ▼
ZI_MAT_QR
   │
   ▼
Behavior Definition
   │
   ▼
QRGEN Action
   │
   ▼
ZCL_QR_GENERATOR
   │
   ▼
QRServer URL
   │
   ▼
QR_URL
Frontend
ZC_MAT_QR
   │
   ▼
Fiori Elements List Report
   │
   │ Select records
   ▼
QRGEN
   │
   ▼
Object Page
   │
   ▼
QRCode.fragment.xml
   │
   ▼
sap.m.Image
   │
   ▼
QrUrl
   │
   ▼
Actual QR Code
Step 17 — Important Difference: XSTRING vs URL

You previously received a value beginning with:

89504E470D0A1A0A...

That is a PNG binary represented as hexadecimal.

It means:

89504E47...
     ↓
PNG image binary

That approach requires proper media/image handling through RAP/OData.

Your current approach is much simpler:

QR Text
   ↓
QRServer
   ↓
QR Image URL
   ↓
QrUrl
   ↓
sap.m.Image

So for now, don't convert the QR image to XSTRING.

Step 18 — Final Testing

Test in this order:

Test 1 — Database

Check:

QR_TEXT
QR_URL

Both must be populated.

Test 2 — Browser

Copy the QR_URL and open it directly in a browser.

You should see the QR code.

Test 3 — Fiori

Open:

List Report

Select:

1300

Click:

Generate QR

Navigate to Object Page.

Test 4 — Object Page

You should see:

Material Number
1300

Material Description
TATA MOTORS

Material Type
EA

QR Text
Material: 000000000000001300...

QR CODE

[ ACTUAL QR IMAGE ]
What I recommend we do next

Since your RAP action and QR URL are already working, don't change the backend unnecessarily.

The next step is specifically:

Fiori Elements Object Page → Custom Section → XML Fragment → sap.m.Image → bind QrUrl.

If you give me your current manifest.json + controller extension .js, I can provide the exact final code for your project to display the QR image under the Object Page, including the correct Fiori Elements extension configuration.
