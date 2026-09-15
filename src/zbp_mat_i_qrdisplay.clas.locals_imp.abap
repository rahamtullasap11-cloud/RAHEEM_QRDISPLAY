CLASS lhc_QRcode DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      keys REQUEST requested_authorizations FOR QRcode RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations FOR QRcode RESULT result.

    METHODS qrgen FOR MODIFY
       keys FOR ACTION QRcode~qrgen RESULT result.

ENDCLASS.

CLASS lhc_QRcode IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD qrgen.
    READ ENTITIES OF zmat_i_qrdisplay IN LOCAL MODE
     ENTITY QRcode
     ALL FIELDS WITH CORRESPONDING #( keys )
     RESULT DATA(lt_materials).

    LOOP AT lt_materials ASSIGNING FIELD-SYMBOL(<ls_material>).

      DATA(lv_qr_text) =
        |Material: { <ls_material>-Material }; | &&
        |Description: { <ls_material>-Materialdescription }; | &&
        |Type: { <ls_material>-Mattype }|.

      "QR generation will happen here
*      DATA(lv_qr_image) = zcl_qr_generators=>generate(
*        iv_text = lv_qr_text
*      ).

      TRY.
          DATA(lv_qr_image) = zcl_qr_generators=>generate_qr( iv_text = lv_qr_text  ).
        CATCH cx_web_http_client_error cx_http_dest_provider_error.
          "handle exception
      ENDTRY.

      MODIFY ENTITIES OF zmat_i_qrdisplay IN LOCAL MODE
        ENTITY QRcode
        UPDATE FIELDS ( QrText QRUrl )
        WITH VALUE #(
          (
            %tky   = <ls_material>-%tky
            QrText = lv_qr_text
            QRUrl = lv_qr_image
          )
        )
        FAILED DATA(lt_failed)
        REPORTED DATA(lt_reported).

    ENDLOOP.

    READ ENTITIES OF zmat_i_qrdisplay IN LOCAL MODE
      ENTITY QRcode
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

ENDCLASS.
