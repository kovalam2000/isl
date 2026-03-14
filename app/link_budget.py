"""
Ka-band Inter-Satellite Link (ISL) budget calculator.

Physics background
------------------
Satellites communicate across vacuum, so there is no atmospheric absorption
on the in-space path.  The dominant loss mechanism is free-space path loss
(FSPL), which grows with the square of distance and the square of frequency:

    FSPL [dB] = 20·log10(4·π·d·f / c)

A link closes (signal gets through) when the received power exceeds the
receiver noise floor by at least the required SNR plus a design margin:

    P_rx = P_tx + G_tx + G_rx − FSPL   [all in dB / dBm / dBi]

    Link margin = P_rx − (kTB + NF + SNR_req)

When the link margin drops below zero the carrier-to-noise ratio is
insufficient and the link is considered failed.

Beyond the power budget, the link can also be blocked by the Earth's body
(geometric occultation): this happens whenever the straight line between
the two satellites passes closer to Earth's centre than Earth's radius.

Typical Ka-band ISL parameters used here as defaults:
  • Frequency      : 26 GHz  (Ka-band)
  • Tx power       : 10 W  → 40 dBm
  • Antenna gain   : 35 dBi each side  (moderate phased-array)
  • Bandwidth      : 500 MHz
  • Noise figure   : 5 dB
  • Required SNR   : 10 dB  (≈ QPSK @ BER 10⁻⁶)
  • Min link margin: 3 dB   (design margin)

With these values the maximum ISL range is ≈ 820 km.
Increasing the antenna gain to 40 dBi per side extends it to ≈ 2 600 km.
"""

import math
from dataclasses import dataclass, field

# Speed of light [m/s]
C = 2.998e8
# Boltzmann constant [dBm/Hz/K]
K_BOLTZMANN_dBmHzK = -198.6  # 10·log10(1.38e-23) + 30


@dataclass
class LinkConfig:
    """Configurable ISL link budget parameters."""
    freq_ghz: float = 26.0        # Carrier frequency [GHz]
    tx_power_dbm: float = 40.0    # Transmit power [dBm]  (10 W)
    tx_gain_dbi: float = 35.0     # Tx antenna gain [dBi]
    rx_gain_dbi: float = 35.0     # Rx antenna gain [dBi]
    bandwidth_mhz: float = 500.0  # Noise bandwidth [MHz]
    noise_figure_db: float = 5.0  # Receiver noise figure [dB]
    snr_req_db: float = 10.0      # Minimum required SNR [dB]
    min_margin_db: float = 3.0    # Minimum link margin [dB]
    earth_radius_km: float = 6378.137   # Earth equatorial radius
    atmosphere_km: float = 100.0  # Atmosphere blockage margin [km]

    @classmethod
    def from_dict(cls, d: dict) -> "LinkConfig":
        return cls(**{k: v for k, v in d.items() if k in cls.__dataclass_fields__})


@dataclass
class LinkBudgetResult:
    is_linked: bool
    reason: str                   # Human-readable status
    range_km: float
    fspl_db: float
    received_power_dbm: float
    noise_floor_dbm: float
    link_margin_db: float
    max_range_km: float           # Theoretical max range with these params
    los_clear: bool               # False if Earth blocks LOS


def fspl_db(distance_km: float, freq_ghz: float) -> float:
    """Free-Space Path Loss in dB."""
    d_m = distance_km * 1e3
    f_hz = freq_ghz * 1e9
    ratio = 4.0 * math.pi * d_m * f_hz / C
    if ratio <= 0:
        return 0.0
    return 20.0 * math.log10(ratio)


def noise_floor_dbm(bandwidth_mhz: float, noise_figure_db: float,
                    temp_k: float = 290.0) -> float:
    """Receiver noise floor in dBm."""
    noise_bw_dbhz = 10.0 * math.log10(bandwidth_mhz * 1e6)
    temp_db = 10.0 * math.log10(temp_k)
    return K_BOLTZMANN_dBmHzK + temp_db + noise_bw_dbhz + noise_figure_db


def max_range_km(cfg: LinkConfig) -> float:
    """Maximum closed-link range given the link configuration."""
    n_floor = noise_floor_dbm(cfg.bandwidth_mhz, cfg.noise_figure_db)
    p_rx_min = n_floor + cfg.snr_req_db + cfg.min_margin_db
    fspl_max = cfg.tx_power_dbm + cfg.tx_gain_dbi + cfg.rx_gain_dbi - p_rx_min
    # FSPL = 20·log10(4·π·d·f/c) → d = 10^((FSPL/20)) · c / (4πf)
    d_m = (10.0 ** (fspl_max / 20.0)) * C / (4.0 * math.pi * cfg.freq_ghz * 1e9)
    return d_m / 1e3


def is_los_clear(pos1_km, pos2_km, cfg: LinkConfig) -> bool:
    """
    Check geometric line-of-sight between two satellites.

    The line segment between the satellites is parameterised as
        P(t) = pos1 + t·(pos2 − pos1),  t ∈ [0, 1]
    The minimum distance from the Earth centre to this segment is computed
    analytically.  If it is less than (R_earth + atmosphere) the Earth body
    blocks the path.
    """
    import numpy as np
    p1 = np.asarray(pos1_km, dtype=float)
    p2 = np.asarray(pos2_km, dtype=float)
    d = p2 - p1
    dd = float(np.dot(d, d))
    if dd == 0.0:
        return True
    t = max(0.0, min(1.0, float(-np.dot(p1, d) / dd)))
    closest = p1 + t * d
    min_dist = float(np.linalg.norm(closest))
    exclusion = cfg.earth_radius_km + cfg.atmosphere_km
    return min_dist > exclusion


def compute_link_budget(pos1_km, pos2_km, cfg: LinkConfig) -> LinkBudgetResult:
    """
    Full link budget for a satellite pair.

    Steps
    -----
    1. Geometric LOS check (Earth occultation).
    2. Range and FSPL.
    3. Received power.
    4. Compare against noise floor + SNR requirement + margin.
    """
    import numpy as np

    # --- Geometric LOS ---
    los_ok = is_los_clear(pos1_km, pos2_km, cfg)

    r_km = float(np.linalg.norm(np.asarray(pos2_km) - np.asarray(pos1_km)))
    if r_km < 1e-3:
        r_km = 1e-3

    fspl = fspl_db(r_km, cfg.freq_ghz)
    p_rx = cfg.tx_power_dbm + cfg.tx_gain_dbi + cfg.rx_gain_dbi - fspl
    n_floor = noise_floor_dbm(cfg.bandwidth_mhz, cfg.noise_figure_db)
    margin = p_rx - n_floor - cfg.snr_req_db
    m_range = max_range_km(cfg)

    if not los_ok:
        return LinkBudgetResult(
            is_linked=False,
            reason="Earth occultation — Earth's body blocks the direct path",
            range_km=r_km,
            fspl_db=fspl,
            received_power_dbm=p_rx,
            noise_floor_dbm=n_floor,
            link_margin_db=margin,
            max_range_km=m_range,
            los_clear=False,
        )

    if margin < cfg.min_margin_db:
        return LinkBudgetResult(
            is_linked=False,
            reason=(
                f"Insufficient link margin ({margin:.1f} dB < "
                f"{cfg.min_margin_db} dB required) — "
                f"range {r_km:.0f} km exceeds budget limit {m_range:.0f} km"
            ),
            range_km=r_km,
            fspl_db=fspl,
            received_power_dbm=p_rx,
            noise_floor_dbm=n_floor,
            link_margin_db=margin,
            max_range_km=m_range,
            los_clear=True,
        )

    return LinkBudgetResult(
        is_linked=True,
        reason=f"Link active — {margin:.1f} dB margin, {r_km:.0f} km range",
        range_km=r_km,
        fspl_db=fspl,
        received_power_dbm=p_rx,
        noise_floor_dbm=n_floor,
        link_margin_db=margin,
        max_range_km=m_range,
        los_clear=True,
    )
