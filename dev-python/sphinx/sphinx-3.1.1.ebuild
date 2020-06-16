# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3+ pypy3 )
PYTHON_REQ_USE="threads(+)"

inherit distutils-r1

DESCRIPTION="Python documentation generator"
HOMEPAGE="http://www.sphinx-doc.org/"
SRC_URI="https://files.pythonhosted.org/packages/1b/2f/d53f8292784836e64125917e571b689698e838d8b88f210edef2f9c93970/Sphinx-3.1.1.tar.gz -> Sphinx-3.1.1.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE="doc latex test"

# Tests automagically use latex, bug 667414
#REQUIRED_USE="test? ( latex )"
RESTRICT="!test? ( test )"

RDEPEND="
	<dev-python/alabaster-0.8[${PYTHON_USEDEP}]
	dev-python/Babel[${PYTHON_USEDEP}]
	dev-python/docutils[${PYTHON_USEDEP}]
	dev-python/imagesize[${PYTHON_USEDEP}]
	dev-python/jinja[${PYTHON_USEDEP}]
	dev-python/pygments[${PYTHON_USEDEP}]
	dev-python/requests[${PYTHON_USEDEP}]
	dev-python/snowballstemmer[${PYTHON_USEDEP}]
	dev-python/sphinxcontrib-applehelp[${PYTHON_USEDEP}]
	dev-python/sphinxcontrib-devhelp[${PYTHON_USEDEP}]
	dev-python/sphinxcontrib-jsmath[${PYTHON_USEDEP}]
	dev-python/sphinxcontrib-htmlhelp[${PYTHON_USEDEP}]
	dev-python/sphinxcontrib-serializinghtml[${PYTHON_USEDEP}]
	dev-python/sphinxcontrib-qthelp[${PYTHON_USEDEP}]
	dev-python/sphinx_rtd_theme[${PYTHON_USEDEP}]
	dev-python/packaging[${PYTHON_USEDEP}]
	latex? (
		dev-texlive/texlive-latexextra
		dev-texlive/texlive-luatex
		app-text/dvipng
	)"
DEPEND="${RDEPEND}
	dev-python/setuptools[${PYTHON_USEDEP}]
	test? (
		dev-python/html5lib[${PYTHON_USEDEP}]
		dev-python/pytest[${PYTHON_USEDEP}]
		virtual/imagemagick-tools[jpeg,png,svg]
		dev-texlive/texlive-latexextra
		dev-texlive/texlive-luatex
		app-text/dvipng
	)"

S="${WORKDIR}/${P^}"

python_prepare_all() {
	# remove tests that fail due to network-sandbox
	rm tests/test_build_linkcheck.py || die "Failed to remove web tests"
	sed -i -e 's:test_latex_images:_&:' tests/test_build_latex.py || die
	sed -i -e 's:test_latex_doc:_&:' tests/test_build_latex.py || die

	# requires specific locales
	sed -i -e 's:test_babel_with_language_:_&:' tests/test_build_latex.py || die
	sed -i -e 's:test_polyglossia_with_language_:_&:' tests/test_build_latex.py || die

	# fail for unknown reasons. TODO: find out why
	sed -i -e 's:test_build_latex_doc:_&:' tests/test_build_latex.py || die
	rm tests/test_ext_imgconverter.py || die "Failed to remove broken test"

	# fails when additional sphinx themes are installed
	sed -i -e 's:test_theme_api:_&:' tests/test_theming.py || die

	# fail under pypy3
	sed -i -e 's:test_partialmethod:_&:' tests/test_autodoc.py || die
	sed -i -e 's:test_partialfunction:_&:' tests/test_autodoc.py || die

	distutils-r1_python_prepare_all
}

python_compile() {
	distutils-r1_python_compile

	# Generate the grammar. It will be caught by install somehow.
	# Note that the tests usually do it for us. However, I don't want
	# to trust USE=test really running all the tests, especially
	# with FEATURES=test-fail-continue.
	pushd "${BUILD_DIR}"/lib >/dev/null || die
	"${EPYTHON}" -m sphinx.pycode.__init__ || die "Grammar generation failed."
	popd >/dev/null || die
}

python_compile_all() {
	if use doc; then
		esetup.py build_sphinx
		HTML_DOCS=( "${BUILD_DIR}"/sphinx/html/. )
	fi
}

python_test() {
	mkdir -p "${BUILD_DIR}/sphinx_tempdir" || die
	local -x SPHINX_TEST_TEMPDIR="${BUILD_DIR}/sphinx_tempdir"
	pytest -vv || die "Tests fail with ${EPYTHON}"
}