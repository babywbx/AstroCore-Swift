import Foundation

/// Per-planet residual corrections for the supported civil range.
enum PlanetResiduals {
    private struct Term {
        let amplitude: Double // arcseconds
        let frequency: Double // cycles per Julian century
        let phase: Double // radians
    }

    private static let supportedRangeChebyshevCenter = -0.495
    private static let supportedRangeChebyshevScale = 1.505

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

    static func distanceCorrectionAU(for body: CelestialBody, t: Double) -> Double {
        switch body {
        case .uranus:
            evaluateChebyshev(uranusDistanceChebyshev, t: t)
        case .neptune:
            evaluateChebyshev(neptuneDistanceChebyshev, t: t)
                + evaluateAnnualChebyshev(
                    sinCoefficients: neptuneDistanceAnnualSin1Chebyshev,
                    cosCoefficients: neptuneDistanceAnnualCos1Chebyshev,
                    harmonic: 1.0,
                    t: t
                )
        case .pluto:
            evaluateChebyshev(plutoDistanceChebyshev, t: t)
                + plutoLowerBoundaryDistanceCorrectionAU(t: t)
                + evaluateChebyshev(plutoDistanceRefinementChebyshev, t: t)
        default:
            0.0
        }
    }

    private static func evaluateChebyshev(_ coefficients: [Double], t: Double) -> Double {
        guard let first = coefficients.first else { return 0.0 }
        let x = (t - supportedRangeChebyshevCenter) / supportedRangeChebyshevScale
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

    private static func evaluateAnnualChebyshev(
        sinCoefficients: [Double],
        cosCoefficients: [Double],
        harmonic: Double,
        t: Double
    ) -> Double {
        let phase = 2.0 * Double.pi * 100.0 * harmonic * t
        return evaluateChebyshev(sinCoefficients, t: t) * Foundation.sin(phase)
            + evaluateChebyshev(cosCoefficients, t: t) * Foundation.cos(phase)
    }

    private static func plutoLowerBoundaryDistanceCorrectionAU(t: Double) -> Double {
        let x = (t - plutoLowerBoundaryDistanceCenter) / plutoLowerBoundaryDistanceWidth
        return plutoLowerBoundaryDistanceAmplitude * Foundation.exp(-(x * x))
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

    private static let uranusDistanceChebyshev: [Double] = [
        1.138195104260e-05, -3.951210117974e-08, 2.292829621380e-05,
        3.839375181021e-06, 2.328557616328e-05, 9.297536277785e-06,
        6.573081806677e-06, -3.121216166914e-06, -1.851797740982e-05,
        -1.106608822563e-05, 5.706892406082e-07, 8.245848413621e-06,
        4.306369017584e-06, -3.625525126340e-08, -1.985683544556e-06,
        -2.484225229167e-06, 1.959953165468e-07, 7.056904304173e-07,
        7.404472779754e-07, -4.133989873442e-07, -7.439409511270e-08,
        -1.224973570845e-07, 5.064219891199e-07, -2.222592545346e-07,
        1.518532315200e-07, -4.599220648795e-07, 5.126920812909e-07,
        -2.589121361759e-08, 3.445290400611e-07, -1.244309648594e-07,
        1.424245918413e-07, -1.301897210106e-07, 6.078306670109e-08,
        -4.318025319433e-07, 2.364644061846e-07, -2.431865472272e-07,
        3.473347309835e-07, -3.023559037503e-07, 3.860782883565e-07,
        -1.249262393309e-07, 3.938542236135e-07, -4.321626909821e-08,
        9.017624353990e-08, -2.116703996031e-07, -6.783917350339e-09,
        -3.841978397066e-07, 2.124095933091e-07, -3.267084553143e-07,
        5.188269694922e-07, -9.267809089716e-08, 2.779345765566e-07,
        -1.420475478939e-07, 1.033424766987e-07, -2.644638516297e-07,
        3.866633299070e-07, -1.714215092217e-07, 2.103558907545e-07,
        -1.293216925373e-07, 5.386946263678e-08, -3.943322384216e-07,
        3.746357621912e-07, -1.661361596683e-07, 3.107385077737e-07,
        4.341236592110e-08, -7.244181197835e-08, -3.434161016154e-07,
        2.903965837432e-07, 1.746214489246e-07, -8.690250868320e-08,
        -3.245478626423e-07, 1.897554320412e-07, 3.033302443157e-08,
        1.711653986121e-07, -1.030825219166e-07, 6.739226581940e-08,
        -4.148725976446e-08, 2.789942770642e-09, -9.636855578886e-09,
        1.561844884645e-07, -7.042493443880e-08, -1.413739890473e-08
    ]

    private static let neptuneDistanceChebyshev: [Double] = [
        -2.869024042138e-05, 1.192546757079e-05, 1.076331298635e-05,
        7.721933650183e-06, 1.581600033870e-05, -6.519104891452e-06,
        -1.115353889715e-05, 1.705674851572e-06, 1.363436736844e-06,
        2.265806072292e-07, 1.025049054694e-06, 1.534362048033e-08,
        -1.215158869684e-07, -4.611390279505e-08, 4.257981269069e-07,
        3.318938365688e-07, 2.307278824509e-08, 6.455609125014e-08,
        -6.495940658330e-08, 1.036461958225e-08, 3.619899636661e-07,
        -1.609182604830e-07, 1.708019706641e-07, -2.429426212336e-07,
        -1.232714703008e-07
    ]

    private static let neptuneDistanceAnnualSin1Chebyshev: [Double] = [
        -3.857580209184e-06, -3.669557110788e-07, -4.753379827499e-06,
        3.865883977703e-07, 1.977791060614e-06, 1.169203057147e-06,
        2.695202084943e-06, -3.903254989967e-07, -7.305566709289e-07,
        -1.680514183789e-07, -2.797425159061e-07, 2.420156300297e-07,
        3.150810293689e-07
    ]

    private static let neptuneDistanceAnnualCos1Chebyshev: [Double] = [
        1.447828085195e-07, 2.952883751373e-06, 1.053704103480e-06,
        5.928828700773e-06, 6.421276004422e-07, 1.743066075638e-06,
        -9.556686845209e-07, -1.868644989026e-06, 1.028537631172e-08,
        1.180215039137e-08, 2.531951057934e-07, 3.962960933259e-07,
        -1.499336127675e-07
    ]

    private static let plutoDistanceChebyshev: [Double] = [
        -1.092115176113e-04, -1.266514517183e-04, -2.201650525885e-04,
        -5.253520053307e-05, -5.453723713497e-05, -1.391785096324e-04,
        -1.391972224666e-04, -1.225347596060e-04, -1.059935103821e-04,
        -1.129631143156e-04, -1.107697273111e-04, -1.131016374656e-04,
        -1.030954933081e-04, -1.043820339996e-04, -9.681429734171e-05,
        -9.906156640453e-05, -9.042023178972e-05, -9.154245174531e-05,
        -8.272482854058e-05, -8.423251764334e-05, -7.527578832942e-05,
        -7.669940071558e-05, -6.741514321365e-05, -6.875719833404e-05,
        -5.953474867084e-05, -6.082438654443e-05, -5.159559777391e-05,
        -5.357671152599e-05, -4.384845471175e-05, -4.637672722206e-05,
        -3.656910601310e-05, -3.993313504978e-05, -2.961976846491e-05,
        -3.396603653133e-05, -2.339033617253e-05, -2.830631490930e-05,
        -1.781964401695e-05, -2.298888696652e-05, -1.287942531622e-05,
        -1.835180263119e-05, -7.942259102642e-06, -1.422462111856e-05,
        -3.675479044171e-06, -1.006909151178e-05, -1.986421031172e-06,
        -7.521089453402e-06, -4.569941188122e-07, -8.072622722140e-06,
        6.469759982854e-06
    ]

    private static let plutoLowerBoundaryDistanceCenter = -1.999958928246
    private static let plutoLowerBoundaryDistanceAmplitude = 2.029007318924414e-04
    private static let plutoLowerBoundaryDistanceWidth = 3.0e-05

    private static let plutoDistanceRefinementChebyshev: [Double] = [
        -1.093663739850e-07, 8.926212756036e-07, -2.178821798799e-07,
        8.906329125735e-07, -2.154609201974e-07, 8.869928880718e-07,
        -2.111945718453e-07, 8.818287055023e-07, -2.048239322437e-07,
        8.756126579740e-07, -1.962738157461e-07, 8.683574761598e-07,
        -1.851538526491e-07, 8.598265006503e-07, -1.714644413199e-07,
        8.498775792265e-07, -1.551674777149e-07, 8.380355148420e-07,
        -1.364530291819e-07, 8.239638396620e-07, -1.152108291652e-07,
        8.072490559395e-07, -9.024446920730e-08, 7.891345842029e-07,
        -6.306133101242e-08, 7.709635871735e-07, -3.604301763752e-08,
        7.473703008342e-07, -3.174277779080e-10, 7.172770894306e-07,
        5.154056160679e-08, 7.018455362853e-07, 8.365678934120e-08,
        6.923978825344e-07, 8.889796591628e-08, 6.072120696559e-07,
        2.186597969936e-07, 5.255727255785e-07, 4.170022583589e-07,
        7.068588901036e-07, 1.562891774217e-07, 7.080760520716e-07,
        -4.970871839532e-08, -1.498575573690e-07, 1.407480959806e-06,
        6.156243439601e-09, 1.979882226754e-06, 3.126601338794e-06,
        -3.671336278146e-06, -2.421440542817e-06, 3.572596655891e-06,
        -5.386239033707e-07, 3.766424829694e-06, 3.299773827027e-07,
        3.038052379429e-06, 7.858476620821e-07, 1.623247221943e-06,
        1.407566025036e-06, 3.451577825656e-07, 1.365164534786e-06,
        -5.624897554865e-07, 1.805398255117e-07, -1.584772587754e-06,
        -7.242645466681e-07, -2.123820593625e-06, -1.040267053480e-06,
        -1.495329663418e-06, -2.198197771124e-06, -6.687534852360e-07,
        -2.476675163709e-06, 2.090555621201e-07, -1.349641952814e-06,
        1.440757177688e-06, -1.360223646177e-06, 1.911716159967e-06,
        4.727318725783e-07, 1.662203316190e-06, 7.405258985758e-07,
        1.233021846385e-06, 1.081919315683e-06, 2.240452488881e-07
    ]
    // swiftlint:enable comma line_length
}
