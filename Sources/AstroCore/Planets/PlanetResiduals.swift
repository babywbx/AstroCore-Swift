import Foundation

/// Per-planet residual corrections for the supported civil range.
enum PlanetResiduals {
    private struct Term {
        let amplitude: Double // arcseconds
        let frequency: Double // cycles per Julian century
        let phase: Double // radians
    }

    private static let plutoChebyshevCenter = -0.495
    private static let plutoChebyshevScale = 1.505

    /// Apply residual correction for a planet.
    /// t: Julian centuries from J2000.0 in TT.
    /// Returns correction in arcseconds.
    static func correctionArcsec(for body: CelestialBody, t: Double) -> Double {
        let terms: [Term]
        switch body {
        case .mercury: terms = mercuryTerms
        case .venus: terms = venusTerms
        case .mars: terms = marsTerms
        case .jupiter: terms = jupiterTerms
        case .saturn: terms = saturnTerms
        case .uranus: terms = uranusTerms
        case .neptune: terms = neptuneTerms
        case .pluto: terms = plutoTerms
        default: return 0.0
        }
        var total = 0.0
        for term in terms {
            total += term.amplitude * Foundation.sin(
                2.0 * .pi * term.frequency * t + term.phase
            )
        }
        if body == .pluto {
            total += evaluateChebyshev(plutoLongitudeChebyshev, t: t)
        }
        return total
    }

    static func latitudeCorrectionArcsec(for body: CelestialBody, t: Double) -> Double {
        switch body {
        case .pluto:
            evaluateChebyshev(plutoLatitudeChebyshev, t: t)
        default:
            0.0
        }
    }

    private static func evaluateChebyshev(_ coefficients: [Double], t: Double) -> Double {
        guard let first = coefficients.first else { return 0.0 }
        let x = (t - plutoChebyshevCenter) / plutoChebyshevScale
        guard coefficients.count > 1 else { return first }

        var previous = 1.0
        var current = x
        var result = first + coefficients[1] * current
        for coefficient in coefficients.dropFirst(2) {
            let next = 2.0 * x * current - previous
            result += coefficient * next
            previous = current
            current = next
        }
        return result
    }

    // swiftlint:disable comma line_length
    private static let mercuryTerms: [Term] = [
        Term(amplitude: 0.3269714991, frequency: 0.3978871012, phase: -0.1291443299),
        Term(amplitude: 0.2107398676, frequency: 0.7957742023, phase: -2.2549451108),
        Term(amplitude: 0.1793117937, frequency: 17.1091453504, phase: 2.0072117340),
        Term(amplitude: 0.1554924996, frequency: 16.7112582493, phase: -2.3645765487),
        Term(amplitude: 0.1413230490, frequency: 1.1936613035, phase: 1.6011219489),
        Term(amplitude: 0.1397145362, frequency: 17.5070324516, phase: -0.1432785722),
        Term(amplitude: 0.1345048170, frequency: 16.3133711481, phase: -0.5121912958),
        Term(amplitude: 0.1107552954, frequency: 15.9154840469, phase: 1.4790520565),
        Term(amplitude: 0.0920675889, frequency: 1.5915484047, phase: -0.9389090819),
        Term(amplitude: 0.0816715943, frequency: 1.9894355059, phase: 2.7724893332),
        Term(amplitude: 0.0787531874, frequency: 17.9049195528, phase: -2.3912749018),
        Term(amplitude: 0.0708662840, frequency: 15.5175969457, phase: -2.4750083571),
        Term(amplitude: 0.0705980677, frequency: 2.3873226070, phase: 0.3673132151),
        Term(amplitude: 0.0682439391, frequency: 33.8204035997, phase: 1.2237921560),
        Term(amplitude: 0.0631217569, frequency: 33.4225164985, phase: -3.0073997354),
        Term(amplitude: 0.0580908441, frequency: 2.7852097082, phase: -2.2389378339),
        Term(amplitude: 0.0515931650, frequency: 3.1830968094, phase: 1.5012683843),
        Term(amplitude: 0.0509003816, frequency: 15.1197098446, phase: 0.1804172268),
        Term(amplitude: 0.0506511270, frequency: 3.5809839106, phase: -1.0186955349)
    ]
    // swiftlint:enable comma line_length

    // swiftlint:disable comma line_length
    private static let venusTerms: [Term] = [
        Term(amplitude: 0.3196878463, frequency: 0.3978871012, phase: -0.0995885755),
        Term(amplitude: 0.2044256492, frequency: 0.7957742023, phase: -2.2180289123),
        Term(amplitude: 0.1411871795, frequency: 1.1936613035, phase: 1.6769708362),
        Term(amplitude: 0.0923457416, frequency: 1.5915484047, phase: -0.7926823870),
        Term(amplitude: 0.0792408545, frequency: 1.9894355059, phase: 2.9020688273),
        Term(amplitude: 0.0686140187, frequency: 2.3873226070, phase: 0.5022801465),
        Term(amplitude: 0.0656352470, frequency: 62.8661619853, phase: -1.5294725817),
        Term(amplitude: 0.0567138007, frequency: 2.7852097082, phase: -2.0318541678),
        Term(amplitude: 0.0557763939, frequency: 62.4682748841, phase: 0.3818036161),
        Term(amplitude: 0.0551257378, frequency: 63.2640490864, phase: 2.6231162539)
    ]
    // swiftlint:enable comma line_length

    // swiftlint:disable comma line_length
    private static let marsTerms: [Term] = [
        Term(amplitude: 0.1939957993, frequency: 0.3978871012, phase: 0.1046766396),
        Term(amplitude: 0.1086077551, frequency: 0.7957742023, phase: -2.0663772851),
        Term(amplitude: 0.0770808794, frequency: 1.1936613035, phase: 1.6873886260),
        Term(amplitude: 0.0519127055, frequency: 1.5915484047, phase: -0.7476026478)
    ]
    // swiftlint:enable comma line_length

    // swiftlint:disable comma line_length
    private static let jupiterTerms: [Term] = [
        Term(amplitude: 0.2899715475, frequency: 0.3978871012, phase: 0.4728912703),
        Term(amplitude: 0.1175550128, frequency: 0.7957742023, phase: -1.8387402180),
        Term(amplitude: 0.0838505408, frequency: 1.1936613035, phase: 1.7570923692),
        Term(amplitude: 0.0595086682, frequency: 1.9894355059, phase: 3.0080768378),
        Term(amplitude: 0.0505956734, frequency: 1.5915484047, phase: -0.3899690161)
    ]
    // swiftlint:enable comma line_length

    // swiftlint:disable comma line_length
    private static let saturnTerms: [Term] = [
        Term(amplitude: 0.2373242105, frequency: 0.3978871012, phase: 0.5560759318),
        Term(amplitude: 0.0875302804, frequency: 0.7957742023, phase: -1.7078861881),
        Term(amplitude: 0.0655686080, frequency: 3.5809839106, phase: -1.1553962722),
        Term(amplitude: 0.0573881261, frequency: 1.1936613035, phase: 1.9355406349)
    ]
    // swiftlint:enable comma line_length

    // Extended-body longitude residual terms.
    // swiftlint:disable comma line_length
    private static let uranusTerms: [Term] = [
        Term(amplitude: 0.7249508971, frequency: 1.0100000000, phase: 2.7910740601),
        Term(amplitude: 0.4092312821, frequency: 0.1550000000, phase: -0.5903753801),
        Term(amplitude: 0.3646124217, frequency: 1.3100000000, phase: 1.5325332666),
        Term(amplitude: 0.3389648322, frequency: 0.6800000000, phase: -1.8553411798),
        Term(amplitude: 0.1175477333, frequency: 1.6700000000, phase: 0.5406221674),
        Term(amplitude: 0.0290128437, frequency: 1.9100000000, phase: -0.2279426210),
        Term(amplitude: 0.0362596206, frequency: 2.2000000000, phase: -0.9931616363),
        Term(amplitude: 0.1143926027, frequency: 0.4050000000, phase: 1.5156198181)
    ]
    // swiftlint:enable comma line_length

    // swiftlint:disable comma line_length
    private static let neptuneTerms: [Term] = [
        Term(amplitude: 5.5003273143, frequency: 0.0500000000, phase: 0.1653775503),
        Term(amplitude: 0.3506340994, frequency: 0.5950000000, phase: -0.7020146719),
        Term(amplitude: 0.0391508764, frequency: 0.8300000000, phase: -1.0564452864),
        Term(amplitude: 0.0245211173, frequency: 1.1600000000, phase: -2.6852640313)
    ]
    // swiftlint:enable comma line_length

    // swiftlint:disable comma line_length
    private static let plutoTerms: [Term] = [
        Term(amplitude: 3.4473761887, frequency: 0.0700000000, phase: -1.5214550602),
        Term(amplitude: 0.6013548547, frequency: 0.5100000000, phase: -1.3224122111),
        Term(amplitude: 0.1891892815, frequency: 1.0100000000, phase: -0.5138740103),
        Term(amplitude: 0.0569568154, frequency: 1.3000000000, phase: -0.5581761523),
        Term(amplitude: 0.0468180357, frequency: 1.7200000000, phase: 0.5739892985),
        Term(amplitude: 0.0638296390, frequency: 0.7500000000, phase: -0.1220618989),
        Term(amplitude: 0.0193877553, frequency: 2.0000000000, phase: -0.5753257802),
        Term(amplitude: 0.0123010197, frequency: 2.6200000000, phase: 0.7788279422)
    ]
    // swiftlint:enable comma line_length

    // swiftlint:disable comma line_length
    private static let plutoLongitudeChebyshev: [Double] = [
        4.662531673058e-01,
        9.338209629634e-01,
        9.259537143834e-01,
        9.252323307169e-01,
        9.135487822252e-01,
        9.111719618382e-01,
        8.918552953446e-01,
        8.912945737629e-01,
        8.665240014323e-01,
        8.604651764254e-01,
        8.402192342457e-01,
        8.228486570168e-01,
        8.066647081756e-01,
        7.803416012802e-01,
        7.622328340529e-01,
        7.345615994788e-01,
        7.120140215940e-01,
        6.841306704728e-01,
        6.580317150897e-01,
        6.261820532151e-01,
        6.064745114492e-01,
        5.757828860103e-01,
        5.405342131539e-01,
        5.175759257804e-01,
        4.891093698583e-01,
        4.592632088760e-01,
        4.281647706791e-01,
        4.024843268216e-01,
        3.729521665962e-01,
        3.474182703930e-01,
        3.202975309558e-01,
        2.987537022395e-01,
        2.683389263977e-01,
        2.517966267641e-01,
        2.196711061201e-01,
        2.068542516729e-01,
        1.754757924226e-01,
        1.644319186733e-01,
        1.368254020320e-01,
        1.305712691731e-01,
        1.018205659675e-01,
        1.011022697655e-01,
        6.973835210758e-02,
        7.040633569745e-02,
        4.503206303409e-02,
        4.632587425101e-02,
        2.554857618609e-02,
        2.868060317337e-02,
        8.271520539887e-03
    ]

    private static let plutoLatitudeChebyshev: [Double] = [
        3.643903095147e-01,
        6.259435516458e-01,
        8.482934899222e-01,
        -7.931623735142e-03,
        3.123504400556e-01,
        7.629340306334e-01,
        7.852859100616e-01,
        5.355588456096e-01,
        3.878888582360e-01,
        4.973326214102e-01,
        5.807975428452e-01,
        5.622624093135e-01,
        4.608371536388e-01,
        4.474200030086e-01,
        4.535033188094e-01,
        4.753457861693e-01,
        4.280445526037e-01,
        4.096107159730e-01,
        3.763993590577e-01,
        3.873685416060e-01,
        3.536731244843e-01,
        3.484815244781e-01,
        3.064949368321e-01,
        3.101089269191e-01,
        2.734595953506e-01,
        2.768378102926e-01,
        2.341070715871e-01,
        2.395385514866e-01,
        1.980201693770e-01,
        2.076711363117e-01,
        1.635834066231e-01,
        1.756689044390e-01,
        1.303706971725e-01,
        1.471353130830e-01,
        1.005170476189e-01,
        1.208649145555e-01,
        7.288186043478e-02,
        9.718641821739e-02,
        4.884111710084e-02,
        7.616938904471e-02,
        2.819501657181e-02,
        5.731179249673e-02,
        1.162550448435e-02,
        4.069202238390e-02,
        -4.476800489257e-04,
        2.592083383640e-02,
        -7.553255895935e-03,
        1.288617084341e-02,
        -8.801789550689e-03
    ]
    // swiftlint:enable comma line_length
}
