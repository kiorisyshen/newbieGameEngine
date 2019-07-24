#pragma once
#include <cmath>
#include <functional>
#include <limits>

using namespace std;

namespace newbieGE
{
template <typename TVAL, typename TPARAM>
struct NewtonRapson {
    typedef std::function<TVAL(TPARAM)> nr_f;
    typedef std::function<TVAL(TPARAM)> nr_fprime;

    static inline TPARAM Solve(TPARAM x0, nr_f f, nr_fprime fprime)
    {
        TPARAM x, x1 = x0;

        do {
            x        = x1;
            TVAL fx  = f(x);
            TVAL fx1 = fprime(x);
            x1       = x - (fx / fx1);
        } while (static_cast<TVAL>(abs(x1 - x)) >= static_cast<TVAL>(10E-6));

        return x1;
    }
};
}  // namespace newbieGE
