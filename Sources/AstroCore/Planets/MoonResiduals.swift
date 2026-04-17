import Foundation

// Empirical Moon longitude residual correction fitted against JPL Horizons on a
// semi-monthly 1900-2050 grid.
//
// The base ELP2000 implementation remains the primary model; these terms only
// remove the remaining few-arcsecond hotspots without materially changing the
// runtime profile.
enum MoonResiduals {
    private static let twoPi = 2.0 * Double.pi

    private struct Term {
        let amplitude: Double // arcseconds
        let angularFrequency: Double // radians per Julian century
        let phase: Double     // radians
    }

    @inline(__always)
    static func correctionArcsec(t: Double) -> Double {
        var total = 0.0
        for term in terms {
            total += term.amplitude * Foundation.sin(
                term.angularFrequency * t + term.phase
            )
        }
        return total
    }

    // swiftlint:disable comma line_length
    private static let terms: [Term] = [
        Term(amplitude: 0.8549065816, angularFrequency: twoPi * 1074.1922762971, phase:  2.3330932704),
        Term(amplitude: 0.7785764588, angularFrequency: twoPi * 1074.8545403392, phase:  3.1268078630),
        Term(amplitude: 0.6096010964, angularFrequency: twoPi * 1064.2583156655, phase: -2.4522267328),
        Term(amplitude: 0.5629659500, angularFrequency: twoPi *   91.3924378107, phase: -2.2130696032),
        Term(amplitude: 0.4969757312, angularFrequency: twoPi * 1068.8941639602, phase:  2.7613470808),
        Term(amplitude: 0.4859280227, angularFrequency: twoPi *    1.3245280842, phase: -2.1889222490),
        Term(amplitude: 0.4263571533, angularFrequency: twoPi *    3.3113202105, phase: -1.0913738118),
        Term(amplitude: 0.4096934343, angularFrequency: twoPi *   29.8018818948, phase: -1.0881325280),
        Term(amplitude: 0.4035556686, angularFrequency: twoPi *    1.9867921263, phase:  2.3683192786),
        Term(amplitude: 0.3860626927, angularFrequency: twoPi *  568.8848121697, phase:  2.8066897771),
        Term(amplitude: 0.3645191979, angularFrequency: twoPi * 1148.3658490130, phase:  0.3976985664),
        Term(amplitude: 0.3478567047, angularFrequency: twoPi *  125.1679039582, phase: -0.3359191303),
        Term(amplitude: 0.3393731759, angularFrequency: twoPi * 1080.1526526760, phase:  2.5443484845),
        Term(amplitude: 0.3348148661, angularFrequency: twoPi *    2.6490561684, phase:  0.1904392670),
        Term(amplitude: 0.3261869908, angularFrequency: twoPi *    5.9603763790, phase: -1.4189550717),
        Term(amplitude: 0.3258529091, angularFrequency: twoPi *   25.1660336001, phase:  2.7114771150),
        Term(amplitude: 0.3031226822, angularFrequency: twoPi *   62.9150840001, phase:  2.0840206504),
        Term(amplitude: 0.3020725466, angularFrequency: twoPi *   73.5113086738, phase:  1.8944704332),
        Term(amplitude: 0.3015763588, angularFrequency: twoPi * 1076.8413324655, phase:  2.6139863687),
        Term(amplitude: 0.2950960905, angularFrequency: twoPi *    0.6622640421, phase: -0.5733330988),
        Term(amplitude: 0.2898557024, angularFrequency: twoPi * 1021.8734169706, phase:  2.5572486019),
        Term(amplitude: 0.2782935973, angularFrequency: twoPi * 1200.0224442973, phase: -2.8822040233),
        Term(amplitude: 0.2761568288, angularFrequency: twoPi * 1079.4903886339, phase:  2.0032853555),
        Term(amplitude: 0.2746055473, angularFrequency: twoPi *  278.8131617269, phase:  1.5353966741),
        Term(amplitude: 0.2652623805, angularFrequency: twoPi *  226.4943024005, phase:  2.6678350598),
        Term(amplitude: 0.2625178114, angularFrequency: twoPi * 1044.3903944023, phase:  1.7752753754),
        Term(amplitude: 0.2495817637, angularFrequency: twoPi * 1147.7035849709, phase: -0.3111638886),
        Term(amplitude: 0.2374185714, angularFrequency: twoPi *    6.6226404211, phase: -0.4959005032),
        Term(amplitude: 0.2359318858, angularFrequency: twoPi * 1077.5035965076, phase: -3.0613307383),
        Term(amplitude: 0.2339893439, angularFrequency: twoPi * 1104.6564222340, phase: -2.4317736178),
        Term(amplitude: 0.2285292779, angularFrequency: twoPi *    5.2981123369, phase: -1.7516717644),
        Term(amplitude: 0.2264632743, angularFrequency: twoPi *   92.0547018528, phase: -1.3717751252),
        Term(amplitude: 0.2116131004, angularFrequency: twoPi *  937.1036195810, phase: -0.9965461143),
        Term(amplitude: 0.2110586781, angularFrequency: twoPi * 1142.4054726341, phase: -0.0372981729),
        Term(amplitude: 0.2109509525, angularFrequency: twoPi *  848.3602379387, phase: -0.9192327178),
        Term(amplitude: 0.1965862512, angularFrequency: twoPi *   87.4188535581, phase: -2.5950528008),
        Term(amplitude: 0.1858035163, angularFrequency: twoPi *   93.3792299370, phase:  0.2389625386),
        Term(amplitude: 0.1854498347, angularFrequency: twoPi *   30.4641459369, phase: -0.1961709995),
        Term(amplitude: 0.1833964880, angularFrequency: twoPi * 1056.3111471602, phase:  0.0723092499),
        Term(amplitude: 0.1785453058, angularFrequency: twoPi *   74.1735727160, phase:  2.7264474797),
    ]
    // swiftlint:enable comma line_length
}
