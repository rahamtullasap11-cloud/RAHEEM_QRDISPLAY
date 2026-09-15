@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Qr code display'
@Metadata.ignorePropagatedAnnotations: true
define root view entity zmat_i_qrdisplay
  as select from zmat_qr
{
  key material            as Material,
      materialdescription as Materialdescription,
      mattype             as Mattype,
      qr_text             as QrText,
      @Semantics.imageUrl: true
      qr_url              as QRUrl,
      lastchangedat       as lastchangedat
}
