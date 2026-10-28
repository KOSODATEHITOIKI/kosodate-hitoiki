/// 利用規約・プライバシーポリシーの公開ページ(運営がサイトのリポジトリで公開する)。
/// アプリ内には、規約の本文を持たず、このページを外部のブラウザで開く。
class LegalLinks {
  LegalLinks._();

  static final terms = Uri.parse(
    'https://kosodatehitoiki.github.io/kosodate-hitoiki-site/terms/',
  );

  static final privacy = Uri.parse(
    'https://kosodatehitoiki.github.io/kosodate-hitoiki-site/privacy/',
  );
}
