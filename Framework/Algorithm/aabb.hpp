#pragma once
#include "geommath.hpp"

namespace newbieGE
{
inline void TransformAabb(const Vector3f& halfExtents, float margin, const Matrix4X4f& trans, Vector3f& aabbMinOut,
                          Vector3f& aabbMaxOut)
{
    Vector3f   halfExtentsWithMargin = halfExtents + Vector3f(margin);
    Vector3f   center;
    Vector3f   extent;
    Matrix3X3f basis;
    GetOrigin(center, trans);
    Shrink(basis, trans);
    // Use absolute to compute new extent (=|basis_x|+|basis_y|+|basis_z|), better draw in 2D to understand
    Absolute(basis, basis);
    DotProduct3(extent, halfExtentsWithMargin, basis);
    aabbMinOut = center - extent;
    aabbMaxOut = center + extent;
}
}  // namespace newbieGE