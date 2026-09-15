@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption for material qr code display'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity zmat_c_qrdisplay 
provider contract transactional_query
as projection on zmat_i_qrdisplay
{
    key Material,
    Materialdescription,
    Mattype,
    QrText,
    @Semantics.imageUrl: true
    QRUrl,
    lastchangedat
}
