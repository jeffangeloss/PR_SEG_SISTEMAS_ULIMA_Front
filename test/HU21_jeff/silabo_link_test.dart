// test/domain/silabo_link_test.dart
// HU21: parsing de enlaces de sílabo de Google Drive.
// Las tres primeras URLs imitan el formato de los sílabos de la BD; los IDs
// son ficticios. En la BD unos sílabos son públicos y otros devuelven el login
// de Google, pero todos deben PARSEAR igual (la accesibilidad la decide
// SilaboService por la firma %PDF, no el parser).

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/domain/silabo/silabo_link.dart';

void main() {
  group('SilaboLink.tryParse con URLs con el formato de la BD', () {
    test('Propuesta de Investigación (/file/d/<id>/view)', () {
      final link = SilaboLink.tryParse(
        'https://drive.google.com/file/d/1SilaboLab-Propuesta00000000-0001/view',
      );

      expect(link, isNotNull);
      expect(link!.fileId, '1SilaboLab-Propuesta00000000-0001');
      expect(
        link.downloadUrl,
        'https://drive.google.com/uc?export=download&id=1SilaboLab-Propuesta00000000-0001',
      );
      expect(
        link.externalViewUrl,
        'https://drive.google.com/file/d/1SilaboLab-Propuesta00000000-0001/view',
      );
    });

    test('Sistemas ERP (/file/d/<id>/view)', () {
      final link = SilaboLink.tryParse(
        'https://drive.google.com/file/d/10SilaboLab-Erp000000000000000002/view',
      );

      expect(link, isNotNull);
      expect(link!.fileId, '10SilaboLab-Erp000000000000000002');
    });

    test('Ingeniería de Software II (no público, pero el parsing es igual)',
        () {
      final link = SilaboLink.tryParse(
        'https://drive.google.com/file/d/1SilaboLabIsw2xxxxxxxxxxxxxxxx003/view',
      );

      expect(link, isNotNull);
      expect(link!.fileId, '1SilaboLabIsw2xxxxxxxxxxxxxxxx003');
      expect(
        link.downloadUrl,
        'https://drive.google.com/uc?export=download&id=1SilaboLabIsw2xxxxxxxxxxxxxxxx003',
      );
    });
  });

  group('SilaboLink.tryParse variantes de Drive', () {
    test('/file/d/<id>/view con query extra (?usp=sharing)', () {
      final link = SilaboLink.tryParse(
        'https://drive.google.com/file/d/1SilaboLab-Propuesta00000000-0001/view?usp=sharing',
      );

      expect(link?.fileId, '1SilaboLab-Propuesta00000000-0001');
    });

    test('/open?id=<id>', () {
      final link = SilaboLink.tryParse(
        'https://drive.google.com/open?id=10SilaboLab-Erp000000000000000002',
      );

      expect(link?.fileId, '10SilaboLab-Erp000000000000000002');
    });

    test('/uc?export=download&id=<id>', () {
      final link = SilaboLink.tryParse(
        'https://drive.google.com/uc?export=download&id=1SilaboLabIsw2xxxxxxxxxxxxxxxx003',
      );

      expect(link?.fileId, '1SilaboLabIsw2xxxxxxxxxxxxxxxx003');
    });

    test('conserva guiones y underscores del FILE_ID', () {
      final link = SilaboLink.tryParse(
        'https://drive.google.com/file/d/1a-B_c2D-e_F3g-H_i4J-k5L/view',
      );

      expect(link?.fileId, '1a-B_c2D-e_F3g-H_i4J-k5L');
    });

    test('tolera espacios alrededor de la URL', () {
      final link = SilaboLink.tryParse(
        '  https://drive.google.com/file/d/1SilaboLab-Propuesta00000000-0001/view  ',
      );

      expect(link?.fileId, '1SilaboLab-Propuesta00000000-0001');
    });
  });

  group('SilaboLink.tryParse casos inválidos', () {
    test('URL vacía o null → null', () {
      expect(SilaboLink.tryParse(''), isNull);
      expect(SilaboLink.tryParse('   '), isNull);
      expect(SilaboLink.tryParse(null), isNull);
    });

    test('URL que no es de Drive → null', () {
      expect(
        SilaboLink.tryParse('https://www.ulima.edu.pe/silabo.pdf'),
        isNull,
      );
      expect(
        SilaboLink.tryParse('https://dropbox.com/file/d/1SilaboLab-Propuesta00000000-0001/view'),
        isNull,
      );
    });

    test('URL de Drive sin FILE_ID reconocible → null', () {
      expect(SilaboLink.tryParse('https://drive.google.com/drive/my-drive'),
          isNull);
      expect(SilaboLink.tryParse('https://drive.google.com/file/d/'), isNull);
      // Segmento demasiado corto para ser un FILE_ID real.
      expect(SilaboLink.tryParse('https://drive.google.com/file/d/abc/view'),
          isNull);
    });

    test('texto que no es URL → null', () {
      expect(SilaboLink.tryParse('no soy una url'), isNull);
    });
  });
}
